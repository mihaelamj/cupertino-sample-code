package maps.api.example;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpResponse.BodyHandlers;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;
import java.util.Date;
import java.util.Map;
import java.util.stream.Collectors;

import io.jsonwebtoken.Jwts;

/**
 * Demo - Apple Maps Server APIs.
 */
public class MapsApiClientDemo {

    public static final String API_SERVER = "https://maps-api.apple.com";

    public static void main(String[] args) {

        // Create JWT using API key downloaded from developer.apple.com.
        String authToken = createJwt();

        // Get an access token (valid for 30 minutes) to use with Apple Maps 
        // Server APIs. Your apps need to refresh this token before it expires.
        String accessToken = getAccessToken(authToken);

        MapsApiClient apiClient = new MapsApiClient(accessToken);

        System.out.println("==== Geocoding ====");
        String geocodeResponse = apiClient.geocode("San Francisco City Hall, San Francisco");
        System.out.println(geocodeResponse);
        System.out.println();

        System.out.println("==== Reverse Geocoding ====");
        // The coordinates of the Windmills in Golden Gate Park, San Francisco, CA.
        String reverseGeocodeResponse = apiClient.reverseGeocode(37.770438, -122.509395);
        System.out.println(reverseGeocodeResponse);
        System.out.println();

        System.out.println("==== SearchAutoComplete ====");
        String searchAutoCompleteResponse = apiClient.searchAutoComplete("coffee");
        System.out.println(searchAutoCompleteResponse);
        System.out.println();

        System.out.println("==== Search ====");
        String searchResponse = apiClient.search("coffee");
        System.out.println(searchResponse);
        System.out.println();

        System.out.println("==== Get ETA between from and to coordinates ====");
        // These coordinates represent San Francisco City Hall and Golden Gate Park in San Francisco, CA.
        String etaResponse = apiClient.eta(37.779268,
                                           -122.419248,
                                           37.770438,
                                           -122.509395);
        System.out.println(etaResponse);
        System.out.println();

        System.out.println("==== Get ETA between from & to addresses ===");
        String etaBetweenAddresses = apiClient.etaBetweenAddresses("San Francisco City Hall, San Francisco",
                                                                   "Golden Gate Park, San Francisco");

        System.out.println(etaBetweenAddresses);
        System.out.println();

        System.out.println("==== Directions ====");
        // These coordinates represent San Francisco City Hall and Golden Gate Park in San Francisco, CA.
        String directionsResponse = apiClient.directions("37.779268,-122.419248", "37.770438,-122.509395");
        System.out.println(directionsResponse);
        System.out.println();
    }

    /**
     * Methods to make calls to APIs such as geocode, search, and so on.
     */
    static class MapsApiClient {

        private HttpClient httpClient = HttpClient.newHttpClient();
        private final String accessToken;

        MapsApiClient(String accessToken) {
            this.accessToken = accessToken;
        }

        /**
         * Makes a geocoding request.
         *
         * @param address - Address to geocode.
         * @return JSON string response.
         */
        String geocode(String address) {
            String urlEncodedParams = URLEncoder.encode(address, StandardCharsets.UTF_8);
            URI uri = URI.create(API_SERVER + "/v1/geocode?q=" + urlEncodedParams);
            HttpResponse<String> response = doHttpGet(uri);
            return response.body();
        }

        /**
         * Makes a reverse geocoding request.
         *
         * @param latitude - Latitude value for the coordinate.
         * @param longitude - Longitude value for the coordinate.
         * @return JSON string response.
         */
        String reverseGeocode(double latitude, double longitude) {
            String params = String.format("loc=%s,%s",
                                          latitude,
                                          longitude);
            URI uri = URI.create(API_SERVER + "/v1/reverseGeocode?" + params);
            HttpResponse<String> response = doHttpGet(uri);
            return response.body();
        }

        /**
         * Makes a search request.
         *
         * @param query - Query to search.
         * @return JSON string response.
         */
        String search(String query) {
            HttpResponse<String> response = doHttpGet(URI.create(API_SERVER + "/v1/search?q=" + query));
            return response.body();
        }

        /**
         * Makes a searchAutoComplete request.
         *
         * @param query - Query to searchAutoComplete.
         * @return JSON string response.
         */
        String searchAutoComplete(String query) {
            HttpResponse<String> response = doHttpGet(URI.create(API_SERVER + "/v1/searchAutoComplete?q=" + query));
            return response.body();
        }

        /**
         * Makes a directions request.
         *
         * @param origin - Starting point for directions.
         * @param destination - Final point for directions.
         * @return JSON string response
         */
        String directions(String origin, String destination) {
            HttpResponse<String> response = doHttpGet(URI.create(API_SERVER + "/v1/directions?origin=" + origin + "&destination=" + destination));
            return response.body();
        }

        /**
         * Makes an HTTP GET request.
         *
         * @param uri - URI for the request.
         * @return - HTTP response object.
         */
        private HttpResponse<String> doHttpGet(URI uri) {
            HttpRequest httpRequest = HttpRequest.newBuilder()
                                                 .GET()
                                                 .uri(uri)
                                                 .setHeader("Authorization", "Bearer " + accessToken)
                                                 .build();
            try {
                return httpClient.send(httpRequest, BodyHandlers.ofString(StandardCharsets.UTF_8));
            } catch (Exception e) {
                e.printStackTrace();
                throw new RuntimeException("HTTP request failed", e);
            }
        }

        /**
         * Makes an Estimates Time of Arrival (ETA) request.
         * @param fromLatitude - Latitude for the origin.
         * @param fromLongitude - Longitude for the origin.
         * @param toLatitude - Latitude for the destination.
         * @param toLongitude - Longitude for the destination.
         *
         * @return - JSON string response.
         */
        String eta(double fromLatitude, double fromLongitude, double toLatitude, double toLongitude) {
            String etaQueryParams = createEtaQueryParams(fromLatitude, fromLongitude, toLatitude, toLongitude);
            HttpResponse<String> response = doHttpGet(URI.create(API_SERVER + "/v1/etas?" + etaQueryParams));
            return response.body();
        }

        /**
         * Makes an Estimated Time of Arrival (ETA) request.
         * @param fromAddress - Origin address.
         * @param toAddress - Destination address.
         * @return - JSON string response.
         */
        String etaBetweenAddresses(String fromAddress, String toAddress) {
            double[] fromCoordinate = getCoordinateFromAddress(fromAddress);
            double[] toCoordinate = getCoordinateFromAddress(toAddress);

            String etaQueryParam = createEtaQueryParams(fromCoordinate[0],
                                                        fromCoordinate[1],
                                                        toCoordinate[0],
                                                        toCoordinate[1]);

            HttpResponse<String> response = doHttpGet(URI.create(API_SERVER + "/v1/etas?" + etaQueryParam));
            return response.body();
        }

        /**
         * Converts an address to a coordinate.
         *
         * @param address - Address for which coordinate should be found.
         * @return - arr[], of size two, representing coordinate, latitude is at index 0, longitude is at index 1.
         */
        private double[] getCoordinateFromAddress(String address) {
            String geocodeResponse = geocode(address);
            try {
                JsonNode jsonNode = new ObjectMapper().readValue(geocodeResponse, JsonNode.class);
                JsonNode coordinate = jsonNode.get("results")
                                              .get(0)
                                              .get("coordinate");
                return new double[]{coordinate.get("latitude").asDouble(),
                                    coordinate.get("longitude").asDouble()};
            } catch (IOException e) {
                e.printStackTrace();
                throw new RuntimeException("JSON parsing failed", e);
            }
        }

        private String createEtaQueryParams(double fromLatitude, double fromLongitude, double toLatitude, double toLongitude) {
            return String.format("origin=%s,%s&destinations=%s,%s",
                                 fromLatitude,
                                 fromLongitude,
                                 toLatitude,
                                 toLongitude);
        }
    }

    /**
     * Makes an HTTP request to exchange Auth token for Access token.
     * @param authToken - The authorization token.
     * @return - An access token.
     */
    public static String getAccessToken(String authToken) {
        HttpRequest httpRequest = HttpRequest.newBuilder()
                                             .GET()
                                             .uri(URI.create(API_SERVER + "/v1/token"))
                                             .setHeader("Authorization", "Bearer " + authToken)
                                             .build();
        HttpResponse<byte[]> response = null;
        try {
            response = HttpClient.newHttpClient()
                                 .send(httpRequest, BodyHandlers.ofByteArray());
            JsonNode jsonNode = new ObjectMapper().readValue(response.body(), JsonNode.class);
            return jsonNode.get("accessToken")
                           .asText();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
            throw new RuntimeException("Failed to get access token", e);
        }
    }

    /**
     * Creates a JWT token, which is auth token in this context.
     * @return - A JWT token represented as String.
     */
    static String createJwt() {
        try {
            // Replace teamId, keyId and key values below
            String teamId = "<your-team-id>";
            String keyId = "<your-key-id>";
            String key = """
                    -----BEGIN PRIVATE KEY-----
                    MIGTAgE.........................................................
                    ................................................................
                    ................................................................
                    ........
                    -----END PRIVATE KEY-----
                            """.lines()
                               .filter(s -> !s.startsWith("---"))
                               .collect(Collectors.joining());

            byte[] encoded = Base64.getDecoder()
                                   .decode(key);
            KeyFactory keyFactory = KeyFactory.getInstance("EC");
            PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(encoded);
            PrivateKey privateKey = keyFactory.generatePrivate(keySpec);
            return Jwts.builder()
                       .setHeader(Map.of("kid", keyId))
                       .addClaims(Map.of("iss", teamId))
                       .setIssuedAt(new Date(System.currentTimeMillis()))
                       .setExpiration(new Date(System.currentTimeMillis() + 30 * 60 * 1000))
                       .signWith(privateKey)
                       .compact();

        } catch (Exception ex) {
            ex.printStackTrace();
            throw new RuntimeException(ex);
        }
    }
}
