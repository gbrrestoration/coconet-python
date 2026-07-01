"""Shared Reef Rescuer how-to-play copy for web and desktop clients."""

HOW_TO_PLAY_TITLE = "How to play Reef Rescuer"

HOW_TO_PLAY_STEPS: tuple[str, ...] = (
    "Survive as long as you can. You lose when both coral cover and fish biodiversity reach zero.",
    "Threats arrive automatically: cyclones, bleaching from rising DHW, and CoTS outbreaks.",
    "Threats get stronger every full minute you survive.",
    "You start with 3 management points and earn more over time (up to 8). Spend them on interventions.",
    "Coral seeding, coral slicks, fishing regulation, and emperor release take a couple of ticks to help.",
    "Shading, CoTS control, and other actions work immediately.",
    "Beat your best survival time. Use Restart for a new round or Quit to leave.",
)


def how_to_play_payload() -> dict[str, object]:
    return {
        "title": HOW_TO_PLAY_TITLE,
        "steps": list(HOW_TO_PLAY_STEPS),
    }
