/**
 * Created by svatopluk.sejkora on 05.10.2022.
 */

export function setTabNameAndIcon(labelName, icon, iconAlt, thisArg) {
    invokeWorkspaceAPI(thisArg, 'isConsoleNavigation').then(isConsole => {
        if (isConsole) {
            invokeWorkspaceAPI(thisArg, 'getFocusedTabInfo').then(focusedTab => {
                invokeWorkspaceAPI(thisArg, 'setTabLabel', {
                    tabId: focusedTab.tabId,
                    label: labelName
                })
                    .catch(function (error) {
                        console.log(error);
                    });
                invokeWorkspaceAPI(thisArg, 'setTabIcon', {
                    tabId: focusedTab.tabId,
                    icon: icon,
                    iconAlt: iconAlt
                })
                    .catch(function (error) {
                        console.log(error);
                    })

            });
        }
    });
}

function invokeWorkspaceAPI(thisArg, methodName, methodArgs) {
    return new Promise((resolve, reject) => {
        const apiEvent = new CustomEvent("internalapievent", {
            bubbles: true,
            composed: true,
            cancelable: false,
            detail: {
                category: "workspaceAPI",
                methodName: methodName,
                methodArgs: methodArgs,
                callback: (err, response) => {
                    if (err) {
                        return reject(err);
                    } else {
                        return resolve(response);
                    }
                }
            }
        });

        thisArg.dispatchEvent(apiEvent);
    });
}
