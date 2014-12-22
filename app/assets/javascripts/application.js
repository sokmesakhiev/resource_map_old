// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require jquery.fixedheadertable.min
//= require jquery.tablescroll
//= require jquery.timeago
//= require jquery.url
//= require jquery.history
//= require knockout-2.1.0
//= require autocomplete-tagfield
//= require knockout
//= require jquery.fancybox
//= require jquery.blockUI
//= require lodash
//= require password_strength
//= require jquery_strength
//= require i18n
//= require_tree .
//available on sprocket 2.2 and above
//= stub 'mobile/map'



// Update the appcache for offline

$(document).ready(function() {
	if (window.applicationCache) {
   		applicationCache.addEventListener('updateready', function() {        
     		if (window.applicationCache.status == window.applicationCache.UPDATEREADY) {
       			window.applicationCache.swapCache();
       			console.log("appcache updated");
       			window.location.reload();
     		}
   		});
 	}
});