// xeno3.webp is index 0 and is ALWAYS the image shown when the page opens.
// We intentionally do NOT restore the last-viewed image from localStorage, so
// every new tab / LibreWolf launch starts on xeno3. Clicking still cycles.
let currentIndex = 0;

const images = ["xeno3.webp", "xeno.webp", "xeno4.webp", "xeno2.webp", "xeno5.webp", "cover1.webp", "cover2.webp", "cover3.webp"];
const colorSets = [
  // xeno3.webp — sage/gold on near-black (DEFAULT, palette derived from the image)
  {
    "--text-color": "#e5e6e1",
    "--hover-color": "#cfcf81",
    "--accent-color": "#dcd8a3",
    "--accent-color-2": "#caad72",
    "--background-color": "#070706",
  },
  // xeno.webp — crimson on near-black (palette derived from the image)
  {
    "--text-color": "#e0cccd",
    "--hover-color": "#ff8fa3",
    "--accent-color": "#ff5f72",
    "--accent-color-2": "#f8445a",
    "--background-color": "#0a0506",
  },
  // xeno4.webp — gold on dark teal (palette derived from the image)
  {
    "--text-color": "#e2e2cf",
    "--hover-color": "#e7df84",
    "--accent-color": "#d9bd5f",
    "--accent-color-2": "#ece063",
    "--background-color": "#131516",
  },
  // xeno2.webp — warm beige on dark gray (palette derived from the image)
  {
    "--text-color": "#d9d4cc",
    "--hover-color": "#ddc7a7",
    "--accent-color": "#dab89e",
    "--accent-color-2": "#e7d7be",
    "--background-color": "#1f1f1e",
  },
  // xeno5.webp — warm sand on dark gray (palette derived from the image)
  {
    "--text-color": "#dad4c8",
    "--hover-color": "#d9b69c",
    "--accent-color": "#e5d7bb",
    "--accent-color-2": "#e1d1af",
    "--background-color": "#211f1d",
  },
  // cover1.webp
  {
    "--text-color": "#c0caf5",
    "--hover-color": "#bb9af7",
    "--accent-color": "#7aa2f7",
    "--accent-color-2": "#f7768e",
    "--background-color": "#1a1b26",
  },
  {
    "--text-color": "#9fadc6",
    "--hover-color": "#9B5856",
    "--accent-color": "#28725A",
    "--accent-color-2": "#D2C7CB",
    "--background-color": "#15191d",
  },
  {
    "--text-color": "#c0caf5",
    "--hover-color": "#e0af68",
    "--accent-color": "#7aa2f7",
    "--accent-color-2": "#bb9af7",
    "--background-color": "#1a1b26",
  },
];

function preloadImages() {
  for (let i = 0; i < images.length; i++) {
    const img = new Image();
    img.src = "../src/images/" + images[i];
  }
}

function nextImage() {
  currentIndex = (currentIndex + 1) % images.length;
  localStorage.setItem("imgIndex2", currentIndex); // Update currentIndex in localStorage
  const imageElement = document.getElementById("carouselImage");
  imageElement.style.opacity = 0;
  updateColors(currentIndex);

  setTimeout(() => {
    imageElement.src = "../src/images/" + images[currentIndex];
    imageElement.style.opacity = 1;
  }, 200); // Match the transition duration in style.css
}

function updateColors() {
  const colorSet = colorSets[currentIndex];
  // Iterate through the colorSet and set the CSS variables
  for (const [property, value] of Object.entries(colorSet)) {
    document.documentElement.style.setProperty(property, value);
  }
}

// Set colors with current index first
updateColors(currentIndex);

// Set the initial image
document.getElementById("carouselImage").src =
  "../src/images/" + images[currentIndex];

// Image is opacity 0 and text is translated off screen by default
// Add the loaded class to the image and text to animate them in
window.onload = function () {
  document.getElementById("image").classList.add("loaded");
  document.getElementById("text").classList.add("loaded");
	document.getElementsByTagName("html")[0].classList.add("loaded");
  // Preload the remaining images
  preloadImages();
};
