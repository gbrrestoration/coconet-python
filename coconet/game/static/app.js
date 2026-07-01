const POLL_MS = 1000;
const ALL_TIME_BEST_KEY = "reef-rescuer-all-time-best";

const gameShell = document.getElementById("game-shell");
const helpDialog = document.getElementById("help-dialog");
const helpTitle = document.getElementById("help-title");
const helpSteps = document.getElementById("help-steps");
const helpOkBtn = document.getElementById("help-ok-btn");
const helpLink = document.getElementById("help-link");
const startGameBtn = document.getElementById("start-game-btn");
const elapsedEl = document.getElementById("elapsed");
const factEl = document.getElementById("fact");
const eventEl = document.getElementById("event");
const gameOverEl = document.getElementById("game-over");
const metersEl = document.getElementById("meters");
const gridEl = document.getElementById("intervention-grid");
const restartBtn = document.getElementById("restart-btn");
const quitBtn = document.getElementById("quit-btn");
const leaderboardDialog = document.getElementById("leaderboard-dialog");
const leaderboardMessage = document.getElementById("leaderboard-message");
const leaderboardNameInput = document.getElementById("leaderboard-name");
const leaderboardError = document.getElementById("leaderboard-error");
const leaderboardSkipBtn = document.getElementById("leaderboard-skip-btn");
const leaderboardSaveBtn = document.getElementById("leaderboard-save-btn");

const bars = {
  coral: document.getElementById("coral-bar"),
  fish: document.getElementById("fish-bar"),
  dhw: document.getElementById("dhw-bar"),
  cots: document.getElementById("cots-bar"),
};

const values = {
  coral: document.getElementById("coral-val"),
  fish: document.getElementById("fish-val"),
  dhw: document.getElementById("dhw-val"),
  cots: document.getElementById("cots-val"),
};

let sessionId = null;
let pollTimer = null;
let gameStarted = false;
let allTimeBest = Number(localStorage.getItem(ALL_TIME_BEST_KEY) || "0");
let leaderboardPromptedForSession = false;
let pendingLeaderboardScore = null;

async function api(path, options = {}) {
  const response = await fetch(path, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });
  const text = await response.text();
  let payload = {};
  if (text) {
    payload = JSON.parse(text);
  }
  if (!response.ok) {
    throw new Error(payload.error || text || response.statusText);
  }
  return payload;
}

function formatAllTimeBest(seconds) {
  const minutes = Math.floor(seconds / 60);
  const secs = String(seconds % 60).padStart(2, "0");
  return `${minutes}:${secs}`;
}

function updateAllTimeBest(seconds) {
  if (seconds > allTimeBest) {
    allTimeBest = seconds;
    localStorage.setItem(ALL_TIME_BEST_KEY, String(allTimeBest));
  }
}

function syncPlayControls() {
  startGameBtn.disabled = gameStarted;
  restartBtn.disabled = !gameStarted;
  quitBtn.disabled = !gameStarted;
  gameShell.classList.toggle("pre-game", !gameStarted);
}

function showHelpDialog() {
  helpDialog.hidden = false;
  helpDialog.classList.remove("hidden");
}

function hideHelpDialog() {
  helpDialog.hidden = true;
  helpDialog.classList.add("hidden");
}

function renderHelp(help) {
  helpTitle.textContent = help.title;
  helpSteps.replaceChildren();
  for (const step of help.steps) {
    const item = document.createElement("li");
    item.textContent = step;
    helpSteps.appendChild(item);
  }
}

function hideLeaderboardDialog() {
  leaderboardDialog.hidden = true;
  leaderboardDialog.classList.add("hidden");
  leaderboardError.classList.add("hidden");
  leaderboardError.textContent = "";
  pendingLeaderboardScore = null;
}

function showLeaderboardDialog(survivalSeconds) {
  pendingLeaderboardScore = survivalSeconds;
  leaderboardMessage.textContent = `You survived ${formatAllTimeBest(survivalSeconds)} and made the top 10. Add your name to the board.`;
  leaderboardNameInput.value = "";
  leaderboardError.classList.add("hidden");
  leaderboardError.textContent = "";
  leaderboardDialog.hidden = false;
  leaderboardDialog.classList.remove("hidden");
  leaderboardNameInput.focus();
}

async function maybePromptLeaderboard(survivalSeconds) {
  if (leaderboardPromptedForSession || survivalSeconds <= 0) {
    return;
  }
  leaderboardPromptedForSession = true;
  const check = await api("/api/leaderboard/check", {
    method: "POST",
    body: JSON.stringify({ survival_seconds: survivalSeconds }),
  });
  if (check.qualifies) {
    showLeaderboardDialog(survivalSeconds);
  }
}

async function saveLeaderboardScore() {
  if (pendingLeaderboardScore === null) {
    return;
  }
  const result = await api("/api/leaderboard", {
    method: "POST",
    body: JSON.stringify({
      name: leaderboardNameInput.value,
      survival_seconds: pendingLeaderboardScore,
    }),
  });
  if (!result.accepted) {
    leaderboardError.textContent = result.message || "Score was not accepted.";
    leaderboardError.classList.remove("hidden");
    return;
  }
  eventEl.textContent = `${result.message} View the board on Top scorers.`;
  hideLeaderboardDialog();
}

function handleLeaderboardError(error) {
  leaderboardError.textContent = error.message;
  leaderboardError.classList.remove("hidden");
}

function renderState(state) {
  const reef = state.reef;
  elapsedEl.textContent = `${state.elapsed_display} · All-time ${formatAllTimeBest(allTimeBest)}`;
  factEl.textContent = state.fact;
  eventEl.textContent = state.event_message;
  metersEl.textContent = state.meters;
  gameOverEl.classList.toggle("hidden", !state.game_over);

  bars.coral.value = reef.coral_cover;
  bars.fish.value = reef.fish_biodiversity;
  bars.dhw.value = Math.min(16, reef.dhw);
  bars.cots.value = reef.cots_pressure;

  values.coral.textContent = `${Math.round(reef.coral_cover)}%`;
  values.fish.textContent = `${Math.round(reef.fish_biodiversity)}%`;
  values.dhw.textContent = reef.dhw.toFixed(1);
  values.cots.textContent = `${Math.round(reef.cots_pressure)}%`;

  updateAllTimeBest(Math.max(state.high_score_seconds, state.survival_seconds));

  const disabled = !gameStarted || state.game_over;
  gridEl.querySelectorAll("button[data-kind]").forEach((button) => {
    button.disabled = disabled;
  });

  if (state.game_over) {
    maybePromptLeaderboard(state.survival_seconds).catch(showError);
  }
}

function renderInterventions(interventions) {
  gridEl.replaceChildren();
  for (const item of interventions) {
    const button = document.createElement("button");
    button.type = "button";
    button.dataset.kind = item.kind;
    button.textContent = `${item.label} (${item.cost} pt)`;
    button.disabled = !gameStarted;
    button.addEventListener("click", () => useIntervention(item.kind));
    gridEl.appendChild(button);
  }
}

async function loadInterventions() {
  const payload = await api("/api/interventions");
  renderInterventions(payload.interventions);
}

async function createSession() {
  const state = await api("/api/sessions", { method: "POST" });
  sessionId = state.session_id;
  renderInterventions(state.interventions);
  renderState(state);
}

async function refreshSession() {
  if (!sessionId) {
    return;
  }
  const state = await api(`/api/sessions/${sessionId}`);
  renderState(state);
}

async function useIntervention(kind) {
  if (!sessionId || !gameStarted) {
    return;
  }
  const state = await api(`/api/sessions/${sessionId}/interventions`, {
    method: "POST",
    body: JSON.stringify({ kind }),
  });
  renderState(state);
}

function startPolling() {
  if (pollTimer) {
    clearInterval(pollTimer);
  }
  pollTimer = setInterval(() => {
    refreshSession().catch(showError);
  }, POLL_MS);
}

async function startGame() {
  if (gameStarted) {
    return;
  }
  gameStarted = true;
  syncPlayControls();
  try {
    await createSession();
    startPolling();
  } catch (error) {
    gameStarted = false;
    syncPlayControls();
    showError(error);
  }
}

async function restartGame() {
  leaderboardPromptedForSession = false;
  hideLeaderboardDialog();
  if (!sessionId) {
    await startGame();
    return;
  }
  const state = await api(`/api/sessions/${sessionId}/restart`, { method: "POST" });
  renderState(state);
}

function resetToPreGame() {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
  sessionId = null;
  gameStarted = false;
  leaderboardPromptedForSession = false;
  hideLeaderboardDialog();
  syncPlayControls();
  factEl.textContent = "Read how to play, then press Start game.";
  eventEl.textContent = "Press Start game when you are ready.";
  gameOverEl.classList.add("hidden");
  gridEl.querySelectorAll("button[data-kind]").forEach((button) => {
    button.disabled = true;
  });
}

function quitGame() {
  resetToPreGame();
}

function showError(error) {
  eventEl.textContent = `Error: ${error.message}`;
}

async function boot() {
  syncPlayControls();
  try {
    const help = await api("/api/help");
    renderHelp(help);
    await loadInterventions();
    resetToPreGame();
    showHelpDialog();
  } catch (error) {
    renderHelp({
      title: "How to play Reef Rescuer",
      steps: [
        "Survive as long as you can while keeping coral and fish alive.",
        "Spend management points on interventions when threats appear.",
      ],
    });
    showError(error);
    showHelpDialog();
  }
}

startGameBtn.addEventListener("click", () => {
  startGame().catch(showError);
});

helpOkBtn.addEventListener("click", hideHelpDialog);

helpLink.addEventListener("click", showHelpDialog);

restartBtn.addEventListener("click", () => {
  restartGame().catch(showError);
});

quitBtn.addEventListener("click", quitGame);

leaderboardSkipBtn.addEventListener("click", hideLeaderboardDialog);

leaderboardSaveBtn.addEventListener("click", () => {
  saveLeaderboardScore().catch(handleLeaderboardError);
});

leaderboardNameInput.addEventListener("keydown", (event) => {
  if (event.key === "Enter") {
    saveLeaderboardScore().catch(handleLeaderboardError);
  }
});

boot();
