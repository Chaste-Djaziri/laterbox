const BUTTON_ID = "laterbox-social-save";

if (!document.getElementById(BUTTON_ID)) {
  const button = document.createElement("button");
  button.id = BUTTON_ID;
  button.type = "button";
  button.textContent = "Save to LaterBox";
  button.setAttribute("aria-label", "Save this page to LaterBox");
  button.style.cssText = [
    "position: fixed",
    "right: 20px",
    "bottom: 20px",
    "z-index: 2147483647",
    "padding: 12px 16px",
    "border: 1px solid rgba(23, 23, 17, .14)",
    "border-radius: 999px",
    "background: #e7ff57",
    "box-shadow: 0 8px 24px rgba(23, 23, 17, .2)",
    "color: #171711",
    "cursor: pointer",
    "font: 700 13px/1 system-ui, sans-serif",
  ].join(";");

  button.addEventListener("click", async () => {
    button.disabled = true;
    button.textContent = "Saving...";
    const result = await chrome.runtime.sendMessage({
      type: "save-page",
      url: window.location.href,
      title: document.title,
    });
    if (result?.status === "saved") {
      button.textContent = "Saved ✓";
      window.setTimeout(() => button.remove(), 1200);
    } else if (result?.status === "needsAuth") {
      button.disabled = false;
      button.textContent = "Connect in LaterBox";
    } else {
      button.disabled = false;
      button.textContent = "Queued offline";
    }
  });

  document.documentElement.appendChild(button);
}
