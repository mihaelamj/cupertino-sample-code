/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The open graph script that runs in the tab in Web Inspector created by devtools_background.js.
*/
function extractOpenGraphProperties() {
    let title = document.querySelector('meta[property="og:title"]')?.content;
    let description = document.querySelector('meta[property="og:description"]')?.content;
    let imageURL = document.querySelector('meta[property="og:image"]')?.content;
    let readyState = document.readyState;

    return { title, description, imageURL, readyState };
}

async function update() {
    let result = await browser.devtools.inspectedWindow.eval('(' + extractOpenGraphProperties.toString() + ')()');

    let titleElement = document.getElementById("title");
    let descriptionElement = document.getElementById("description");
    let imageElement = document.getElementById("image");
    let emptyElement = document.getElementById("empty");

    titleElement.textContent = result?.title;
    descriptionElement.textContent = result?.description;
    imageElement.src = result?.imageURL ?? "";
    imageElement.classList.toggle("hidden", !result?.imageURL);
    emptyElement.classList.toggle("hidden", (result?.title || result?.description || result?.imageURL));

    if (result?.readyState !== 'ready' || result?.readyState !== 'complete')
        setTimeout(update, 100);
}

let emptyLabel = document.querySelector("#empty > label");
emptyLabel.textContent = browser.i18n.getMessage("no_data");

update();

browser.devtools.network.onNavigated.addListener(update);
