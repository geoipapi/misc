package com.example.geoipfetcher

import android.content.Context
import android.os.Build
import android.provider.Settings
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.decodeFromString
import okhttp3.*
import java.io.IOException

@Serializable
data class GeoIpResponse(
    val ip: String,
    val type: String,
    val country: Country,
    val location: Location,
    val asn: Asn
)

@Serializable data class Country(
    val is_eu_member: Boolean,
    val currency_code: String,
    val continent: String,
    val name: String,
    val country_code: String,
    val state: String,
    val city: String,
    val zip: String,
    val timezone: String
)

@Serializable data class Location(val latitude: Double, val longitude: Double)
@Serializable data class Asn(val number: Int, val name: String, val network: String, val type: String)

interface GeoIpCallback {
    fun onSuccess(data: GeoIpResponse)
    fun onError(e: Exception)
}

class KotlinGeoIP(private val context: Context) {
    private val client = OkHttpClient()
    private val json = Json { ignoreUnknownKeys = true }

    fun fetch(callback: GeoIpCallback) {
        val deviceId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
        val request = Request.Builder()
            .url("https://api.geoipapi.com/")
            .addHeader("X-Device-ID", deviceId)
            .addHeader("X-Device-Model", Build.MODEL)
            .addHeader("X-Device-Manufacturer", Build.MANUFACTURER)
            .addHeader("X-Device-Brand", Build.BRAND)
            .addHeader("X-Device-Hardware", Build.HARDWARE)
            .addHeader("X-Device-Product", Build.PRODUCT)
            .addHeader("X-Device-OS-Version", Build.VERSION.RELEASE)
            .addHeader("X-Device-SDK", Build.VERSION.SDK_INT.toString())
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                callback.onError(e)
            }

            override fun onResponse(call: Call, response: Response) {
                response.use {
                    if (!it.isSuccessful) {
                        callback.onError(IOException("Unexpected HTTP " + it.code))
                        return
                    }
                    try {
                        val body = it.body?.string() ?: throw IOException("Empty response")
                        val data = json.decodeFromString<GeoIpResponse>(body)
                        callback.onSuccess(data)
                    } catch (e: Exception) {
                        callback.onError(e)
                    }
                }
            }
        })
    }
}
