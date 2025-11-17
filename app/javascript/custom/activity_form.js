document.addEventListener("turbo:load", function () {
  const daySelect = document.getElementById("select-day");
  const blocks = document.querySelectorAll(".timeblock-day");

  if (!daySelect || blocks.length === 0) return;

  function updateTimeBlocks() {
    const selectedDay = daySelect.value;
    blocks.forEach((block) => {
      block.style.display =
        block.dataset.day === selectedDay ? "block" : "none";
    });
  }

  daySelect.addEventListener("change", updateTimeBlocks);
  updateTimeBlocks();
});
