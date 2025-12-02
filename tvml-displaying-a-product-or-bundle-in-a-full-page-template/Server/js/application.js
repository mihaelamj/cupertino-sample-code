/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main Javascript file that drives the TVMLKit JS part of the application
*/

let gHostController = null;

class HostController 
{
	constructor(hostURL) {
		this.hostURL = hostURL;
	}

	getRemoteURL(localURL) {
		return this.hostURL + localURL;
	}
}

class DocumentLoader 
{
	constructor(remoteURL) {
		this.remoteURL = remoteURL;
	}

	_loadXHR(completion) {
		// Load the remote document.
		let xhr = new XMLHttpRequest();
		xhr.open('GET', this.remoteURL);
		xhr.onload = () => {
			completion(xhr);
		};
		xhr.onerror = () => {
			completion(null, 'loading error');
		};
		xhr.send();		
	}

	load(completion) {
		this._loadXHR((xhr, error) => {
            let document = null;
            if (xhr) {
                let text = xhr.responseText;
                let res = text.replace(/{HOST_URL}/gi, gHostController.hostURL);
                document = new DOMParser().parseFromString(res, 'text/xml');
            }
            completion(document, error);
		});
	}

	loadString(completion) {
		this._loadXHR((xhr, error) => {
            completion(xhr ? xhr.responseText : null, error);
		});
	}
}

// Launch callback.
App.onLaunch = (options) => {

	// Setup the global host controller.
	let baseURL = options.baseURL || (function(appURL) {
        return appURL.substr(0, appURL.lastIndexOf("/")) + "/../";
    })(options.location);

	gHostController = new HostController(baseURL);
};

App.onDocumentRequest = (request, response) => {
	if (request.requestType == "document") {
		// Setup a document load to update the link.
		new DocumentLoader(gHostController.getRemoteURL(request.url)).load((document, errorStr) => {
				let processor = documentProcessor[request.url];
				if (processor != null) {
					processor(request, document);
				}
				response.document = document;
				response.close(errorStr ? { 'errorStr' : errorStr } : null);	
		});
	} 
    else {
        response.close();
    }
};

let documentProcessor = {
	"templates/Index.xml": (request, document) => {
		// Create data for this template.
		let data = {
			examples : [
				{
					title : "Stand alone",
					url   : "templates/ProductSingle.xml",
					theme : "dark",
					backgroundURL : gHostController.getRemoteURL('resources/images/product_bg_1.jpg'),
					logoURL : gHostController.getRemoteURL('resources/images/product_logo.png'),
				},
				{
					title : "Browser",
					url   : "templates/Browser.xml",
				},
			]
		};

		// Set on the template element.
		let templateElement = document.getElementsByTagName('listTemplate').item(0);
		templateElement.dataItem = data;
	},
	"templates/ProductSingle.xml": (request, document) => {
		let extraInfo = request;

		// Create data for this template.
		extraInfo.supplementaryItems = [
			{
				artworkURL : gHostController.getRemoteURL('resources/images/square_4.jpg'),
				title : "Trending Now Title"
			}, 
			{
				artworkURL : gHostController.getRemoteURL('resources/images/square_5.jpg'),
				title : "Trending Now Title"
			}, 
			{
				artworkURL : gHostController.getRemoteURL('resources/images/square_6.jpg'),
				title : "Trending Now Title"
			}
		];		

		// Set data on the template element.
		let templateElement = document.getElementsByTagName('productUberTemplate').item(0);
		templateElement.dataItem = extraInfo;
	},
	"templates/Browser.xml": (request, document) => {
		// Create data for this template.
		let data = {
			movies : [
				{
					artworkURL : gHostController.getRemoteURL('resources/images/square_1.jpg'),
					backgroundURL : gHostController.getRemoteURL('resources/images/product_bg_1.jpg'),
					logoURL : gHostController.getRemoteURL('resources/images/product_logo.png'),
					title : "Movie Title",
					theme : "dark",
					url : "templates/ProductSingle.xml"
				}, 
				{
					artworkURL : gHostController.getRemoteURL('resources/images/square_2.jpg'),
					backgroundURL : gHostController.getRemoteURL('resources/images/product_bg_2.jpg'),
					logoURL : gHostController.getRemoteURL('resources/images/product_logo.png'),
					title : "Movie Title",
					theme : "dark",
					url : "templates/ProductSingle.xml"
				}, 
				{
					artworkURL : gHostController.getRemoteURL('resources/images/square_3.jpg'),
					backgroundURL : gHostController.getRemoteURL('resources/images/product_bg_3.jpg'),
					logoURL : gHostController.getRemoteURL('resources/images/product_logo.png'),
					title : "Movie Title",
					theme : "dark",
					url : "templates/ProductSingle.xml"
				}, 
				{
					artworkURL : gHostController.getRemoteURL('resources/images/square_4.jpg'),
					backgroundURL : gHostController.getRemoteURL('resources/images/product_bg_1.jpg'),
					logoURL : gHostController.getRemoteURL('resources/images/product_logo.png'),
					title : "Movie Title",
					theme : "dark",
					url : "templates/ProductSingle.xml"
				}
			]
		};

		// Set on the template element.
		let templateElement = document.getElementsByTagName('stackTemplate').item(0);
		templateElement.dataItem = data;

		let superShelf = document.getElementById('super_shelf');
		superShelf.addEventListener("select", (event) => {
			console.log('super_shelf ' + superShelf);
			superShelf.getFeature('Browser').present();
		});
	}
}
