package com.example.geoipfetcher;

import android.content.Context;
import android.os.Build;
import android.provider.Settings;

import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

import java.io.IOException;

public class GeoIpFetcher {

    public interface GeoIpCallback {
        void onSuccess(GeoIpResponse data);
        void onError(Exception e);
    }

    private final OkHttpClient client = new OkHttpClient();
    private final Context context;
    private final Gson gson = new Gson();

    public GeoIpFetcher(Context context) {
        this.context = context;
    }

    public void fetchGeoIp(final GeoIpCallback callback) {
        String deviceId = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
        String appName = context.getApplicationInfo().loadLabel(context.getPackageManager()).toString();

        Request request = new Request.Builder()
                .url("https://api.geoipapi.com/")
                .addHeader("X-App-Name", appName)
                .addHeader("X-Device-ID", deviceId)
                .addHeader("X-Device-Model", Build.MODEL)
                .addHeader("X-Device-Manufacturer", Build.MANUFACTURER)
                .addHeader("X-Device-Brand", Build.BRAND)
                .addHeader("X-Device-Board", Build.BOARD)
                .addHeader("X-Device-Hardware", Build.HARDWARE)
                .addHeader("X-Device-Product", Build.PRODUCT)
                .addHeader("X-Device-OS-Version", Build.VERSION.RELEASE)
                .addHeader("X-Device-SDK", String.valueOf(Build.VERSION.SDK_INT))
                .build();

        client.newCall(request).enqueue(new Callback() {
            @Override public void onFailure(Call call, IOException e) {
                callback.onError(e);
            }

            @Override public void onResponse(Call call, Response response) throws IOException {
                if (!response.isSuccessful()) {
                    callback.onError(new IOException("Unexpected response: " + response));
                    return;
                }
                String body = response.body().string();
                try {
                    GeoIpResponse data = gson.fromJson(body, GeoIpResponse.class);
                    callback.onSuccess(data);
                } catch (Exception e) {
                    callback.onError(e);
                }
            }
        });
    }

    public static class GeoIpResponse {
        public String ip;
        public String type;
        public Country country;
        public Location location;
        public Asn asn;
    }

    public static class Country {
        @SerializedName("is_eu_member") public boolean isEuMember;
        @SerializedName("currency_code") public String currencyCode;
        public String continent;
        public String name;
        @SerializedName("country_code") public String countryCode;
        public String state;
        public String city;
        public String zip;
        public String timezone;
    }

    public static class Location {
        public double latitude;
        public double longitude;
    }

    public static class Asn {
        public int number;
        public String name;
        public String network;
        public String type;
    }
}
