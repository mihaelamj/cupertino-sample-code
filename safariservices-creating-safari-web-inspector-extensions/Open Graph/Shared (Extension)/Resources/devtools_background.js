/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The background script for Web Inspector.
*/
browser.devtools.panels.create(browser.i18n.getMessage("extension_name"), "images/logo.svg", "devtools_tab.html");
