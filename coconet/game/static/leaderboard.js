const rowsEl = document.getElementById("leaderboard-rows");

async function loadLeaderboard() {
  const response = await fetch("/api/leaderboard");
  if (!response.ok) {
    throw new Error("Could not load leaderboard");
  }
  return response.json();
}

function renderRows(entries) {
  rowsEl.replaceChildren();
  if (!entries.length) {
    const row = document.createElement("tr");
    const cell = document.createElement("td");
    cell.colSpan = 3;
    cell.textContent = "No scores yet. Be the first to make the board.";
    row.appendChild(cell);
    rowsEl.appendChild(row);
    return;
  }

  for (const entry of entries) {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${entry.rank}</td>
      <td>${escapeHtml(entry.name)}</td>
      <td>${escapeHtml(entry.elapsed_display)}</td>
    `;
    rowsEl.appendChild(row);
  }
}

function escapeHtml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

loadLeaderboard()
  .then((payload) => renderRows(payload.entries))
  .catch((error) => {
    rowsEl.replaceChildren();
    const row = document.createElement("tr");
    const cell = document.createElement("td");
    cell.colSpan = 3;
    cell.textContent = error.message;
    row.appendChild(cell);
    rowsEl.appendChild(row);
  });
