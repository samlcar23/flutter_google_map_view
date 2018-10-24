import 'dart:async';

import 'package:map_view/location.dart';
import 'package:uri/uri.dart';
import 'map_view.dart';
import 'locations.dart';
import 'map_view_type.dart';

class StaticMapProvider {
  final String googleMapsApiKey;
  static const int defaultZoomLevel = 4;
  static const int defaultWidth = 600;
  static const int defaultHeight = 400;
  static const StaticMapViewType defaultMaptype = StaticMapViewType.roadmap;

  StaticMapProvider(this.googleMapsApiKey);

  ///
  /// Creates a Uri for the Google Static Maps API
  /// Centers the map on [center] using a zoom of [zoomLevel]
  /// Specify a [width] and [height] that you would like the resulting image to be. The default is 600w x 400h
  ///

  Uri getStaticUri(Location center, int zoomLevel,
      {int width, int height, StaticMapViewType mapType, String style}) {
    return _buildUrl(
        null,
        null,
        center,
        zoomLevel ?? defaultZoomLevel,
        width ?? defaultWidth,
        height ?? defaultHeight,
        mapType ?? defaultMaptype, false, style ?? "");
  }

  ///
  /// Creates a Uri for the Google Static Maps API using a list of locations to create pins on the map
  /// [locations] must have at least 1 location
  /// Specify a [width] and [height] that you would like the resulting image to be. The default is 600w x 400h
  ///

  Uri getStaticUriWithMarkers(List<Marker> markers,
      {int width, int height, StaticMapViewType maptype, Location center, bool customIcon, String style}) {
    return _buildUrl(null, markers, center, null, width ?? defaultWidth,
        height ?? defaultHeight, maptype ?? defaultMaptype, customIcon ?? false, style ?? "");
  }

  ///
  /// Creates a Uri for the Google Static Maps API using a list of locations to create a path on the map
  /// [locations] must have at least 2 locations
  /// Specify a [width] and [height] that you would like the resulting image to be. The default is 600w x 400h
  ///

  Uri getStaticUriWithPath(List<Location> points,
      {int width, int height, StaticMapViewType maptype, Location center, String style}) {
    return _buildUrl(points, null, center, null, width ?? defaultWidth,
        height ?? defaultHeight, maptype ?? defaultMaptype, false, style ?? "");
  }

  ///
  /// Creates a Uri for the Google Static Maps API using a list of locations to create a path on the map and
  /// uses a list of locations to create pins on the map
  /// [locations] must have at least 2 locations
  /// Specify a [width] and [height] that you would like the resulting image to be. The default is 600w x 400h
  ///

  Uri getStaticUriWithPathAndMarkers(List<Location> points,List<Marker> markers,
      {int width, int height, StaticMapViewType maptype, Location center, bool customIcon, String style}) {
    return _buildUrl(points, markers, center, null, width ?? defaultWidth,
        height ?? defaultHeight, maptype ?? defaultMaptype, customIcon ?? false, style ?? "");
  }

  ///
  /// Creates a Uri for the Google Static Maps API using a list of locations to create pins on the map
  /// [locations] must have at least 1 location
  /// Specify a [width] and [height] that you would like the resulting image to be. The default is 600w x 400h
  /// Centers the map on [center] using a zoom of [zoomLevel]
  ///
  Uri getStaticUriWithMarkersAndZoom(List<Marker> markers,
      {int width,
      int height,
      StaticMapViewType maptype,
      Location center,
      int zoomLevel, bool customIcon, String style}) {
    return _buildUrl(null, markers, center, zoomLevel, width ?? defaultWidth,
        height ?? defaultHeight, maptype ?? defaultMaptype, customIcon ?? false, style ?? "");
  }

  ///
  /// Creates a Uri for the Google Static Maps API using an active MapView
  /// This method is useful for generating a static image
  /// [mapView] must currently be visible when you call this.
  /// Specify a [width] and [height] that you would like the resulting image to be. The default is 600w x 400h
  ///
  Future<Uri> getImageUriFromMap(MapView mapView,
      {int width, int height, StaticMapViewType maptype, String style}) async {
    var markers = await mapView.visibleAnnotations;
    var center = await mapView.centerLocation;
    var zoom = await mapView.zoomLevel;
    return _buildUrl(null, markers, center, zoom.toInt(), width ?? defaultWidth,
        height ?? defaultHeight, maptype ?? defaultMaptype, false, style ?? "");
  }

  Uri _buildUrl(List<Location> points, List<Marker> locations, Location center, int zoomLevel,
      int width, int height, StaticMapViewType mapType, bool customIcon, String style) {
    var finalUri = new UriBuilder()
      ..scheme = 'https'
      ..host = 'maps.googleapis.com'
      ..port = 443
      ..path = '/maps/api/staticmap';

    var uri;

    if (center == null && (locations == null || locations.length == 0)
        && (points == null || points.length < 2)) {
      center = Locations.centerOfUSA;
    }

    if ((points != null && points.length >= 2) && (locations == null || locations.length == 0)) {
      List<String> locs = new List();
      points.forEach((location) {
        num lat = location.latitude;
        num lng = location.longitude;
        String point = '$lat,$lng';
        locs.add(point);
      });
      String pointsString = locs.join('|');
      finalUri.queryParameters = {
        'path': pointsString,
        'size': '${width ?? defaultWidth}x${height ?? defaultHeight}',
        'maptype': _getMapTypeQueryParam(mapType),
        'key': googleMapsApiKey,
      };

      if (style != "") {
        finalUri.queryParameters['style'] = style;
      }

    }else if ((points != null && points.length >= 2) && (locations != null && locations.length > 0)) {
      List<String> locs = new List();
      points.forEach((location) {
        num lat = location.latitude;
        num lng = location.longitude;
        String point = '$lat,$lng';
        locs.add(point);
      });
      List<String> markers = new List();
      locations.forEach((location) {
        num lat = location.latitude;
        num lng = location.longitude;
        String marker = '$lat,$lng';
        markers.add(marker);
      });
      String pointsString = locs.join('|');
      if(customIcon) {
        String size = '${width ?? defaultWidth}x${height ?? defaultHeight}';
        uri = _createCustomMarkersUri(pointsString, locations, size, style);
      } else {
        String markersString = markers.join('|');
        finalUri.queryParameters = {
          'path': pointsString,
          'markers': markersString,
          'size': '${width ?? defaultWidth}x${height ?? defaultHeight}',
          'maptype': _getMapTypeQueryParam(mapType),
          'key': googleMapsApiKey,
        };

        if (style != "") {
          finalUri.queryParameters['style'] = style;
        }
      }
    }else if (locations == null || locations.length == 0) {
      if (center == null) center = Locations.centerOfUSA;
      finalUri.queryParameters = {
        'center': '${center.latitude},${center.longitude}',
        'zoom': zoomLevel.toString(),
        'size': '${width ?? defaultWidth}x${height ?? defaultHeight}',
        'maptype': _getMapTypeQueryParam(mapType),
        'key': googleMapsApiKey,
      };

      if (style != "") {
        finalUri.queryParameters['style'] = style;
      }
    } else {
      List<String> markers = new List();
      locations.forEach((location) {
        num lat = location.latitude;
        num lng = location.longitude;
        String marker = '$lat,$lng';
        markers.add(marker);
      });
      if (customIcon){
        String size = '${width ?? defaultWidth}x${height ?? defaultHeight}';
        uri = _createCustomMarkersUri(null, locations, size, style);
      } else {
        String markersString = markers.join('|');
        finalUri.queryParameters = {
          'markers': markersString,
          'size': '${width ?? defaultWidth}x${height ?? defaultHeight}',
          'maptype': _getMapTypeQueryParam(mapType),
          'key': googleMapsApiKey,
        };

        if (style != "") {
          finalUri.queryParameters['style'] = style;
        }
      }
    }
    if (center != null)
      finalUri.queryParameters['center'] =
          '${center.latitude},${center.longitude}';

    if (!customIcon) {
      uri = finalUri.build();
    }
    return uri;
  }

  ///
  /// Creates a custom URI that allows the use of custom marker icons.
  /// If there is a path, it should already be formatted correctly.
  /// Locations contain the Custom Marker Icon.
  /// Size is already formatted correctly.
  ///
  Uri _createCustomMarkersUri(String path, List<Marker> locations, String size, String style) {
    Uri uri;

    List<String> icons = new List();
    List<String> markers = new List();

    locations.forEach((location) {

      num lat = location.latitude;
      num lng = location.longitude;
      String marker = '$lat,$lng';
      markers.add(marker);

      String iconUrl = "";
      String markerUrl = "";
      bool isAsset = false;

      try {
        iconUrl = location.markerIcon.asset;
        isAsset = true;
      } catch (exception) {
        isAsset = false;
      }

      if (isAsset) {
        String iconUrl = location.markerIcon.asset;
        markerUrl = ('&markers=icon:$iconUrl%7C$marker');
      } else {
        markerUrl = ('&markers=$marker');
      }

      icons.add(markerUrl);
    });


    String markersString = icons.join('%7C');

    if (style == "") {
      if (path != null) {
        uri = Uri.parse(
            'https://maps.googleapis.com/maps/api/staticmap?&size=$size&path=$path' +
                markersString + '&key=$googleMapsApiKey');
      } else {
        uri = Uri.parse(
            'https://maps.googleapis.com/maps/api/staticmap?&size=$size' +
                markersString + '&key=$googleMapsApiKey');
      }
    } else {
      if (path != null) {
        uri = Uri.parse(
            'https://maps.googleapis.com/maps/api/staticmap?&size=$size&style=$style&path=$path' +
                markersString + '&key=$googleMapsApiKey');
      } else {
        uri = Uri.parse(
            'https://maps.googleapis.com/maps/api/staticmap?&size=$size&style=$style' +
                markersString + '&key=$googleMapsApiKey');
      }
    }


    return uri;
  }

  String _getMapTypeQueryParam(StaticMapViewType maptype) {
    String mapTypeQueryParam;
    switch (maptype) {
      case StaticMapViewType.roadmap:
        mapTypeQueryParam = "roadmap";
        break;
      case StaticMapViewType.satellite:
        mapTypeQueryParam = "satellite";
        break;
      case StaticMapViewType.hybrid:
        mapTypeQueryParam = "hybrid";
        break;
      case StaticMapViewType.terrain:
        mapTypeQueryParam = "terrain";
        break;
    }
    return mapTypeQueryParam;
  }
}
