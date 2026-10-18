package com.example.laterbox.data.api

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ServiceStatusTest {

    @Test
    fun testParseServiceStatusSnapshot() {
        val sampleJson = """
            {
                "status": "operational",
                "label": "All systems operational",
                "totalMonitors": 2,
                "timestamp": "2026-10-18T18:41:50.998Z",
                "statusPageUrl": "https://status.laterbox.dev",
                "monitors": [
                    {
                        "id": "4853271",
                        "name": "laterbox.dev",
                        "status": "up",
                        "label": "Operational",
                        "lastCheckedAt": "2026-10-18T18:39:35.000Z",
                        "checkFrequency": 180
                    },
                    {
                        "id": "4853313",
                        "name": "LaterBox Web API",
                        "status": "up",
                        "label": "Operational",
                        "lastCheckedAt": "2026-10-18T18:40:40.000Z",
                        "checkFrequency": 180
                    }
                ]
            }
        """.trimIndent()

        val snapshot = LaterBoxApiService.parseServiceStatusSnapshot(sampleJson)
        assertEquals("operational", snapshot.status)
        assertEquals("All systems operational", snapshot.label)
        assertEquals(2, snapshot.monitors.size)
        assertEquals("laterbox.dev", snapshot.monitors[0].name)
        assertEquals("up", snapshot.monitors[0].status)
        assertEquals("Operational", snapshot.monitors[0].label)
        assertEquals(180, snapshot.monitors[0].checkFrequency)
        assertEquals("https://status.laterbox.dev", snapshot.statusPageUrl)
    }

    @Test
    fun testParseBetterStackDirectMonitors() {
        val directJson = """
            {
                "data": [
                    {
                        "id": "1001",
                        "type": "monitor",
                        "attributes": {
                            "pronounceable_name": "API Gateway",
                            "status": "up",
                            "paused": false,
                            "last_checked_at": "2026-10-18T19:00:00.000Z",
                            "check_frequency": 60
                        }
                    },
                    {
                        "id": "1002",
                        "type": "monitor",
                        "attributes": {
                            "pronounceable_name": "Sync Engine",
                            "status": "down",
                            "paused": false,
                            "last_checked_at": "2026-10-18T19:00:00.000Z",
                            "check_frequency": 60
                        }
                    }
                ]
            }
        """.trimIndent()

        val snapshot = LaterBoxApiService.parseBetterStackDirectMonitors(directJson)
        assertEquals("outage", snapshot.status)
        assertEquals("Some services are unavailable", snapshot.label)
        assertEquals(2, snapshot.monitors.size)
        assertEquals("API Gateway", snapshot.monitors[0].name)
        assertEquals("up", snapshot.monitors[0].status)
        assertEquals("Operational", snapshot.monitors[0].label)
        assertEquals("Sync Engine", snapshot.monitors[1].name)
        assertEquals("down", snapshot.monitors[1].status)
        assertEquals("Service disruption", snapshot.monitors[1].label)
    }

    @Test
    fun testParseServiceUptimeHistory() {
        val historyJson = """
            {
                "from": "2026-10-11T00:00:00.000Z",
                "to": "2026-10-18T18:42:00.133Z",
                "timeZone": "UTC",
                "unit": "day",
                "monitors": [
                    {
                        "id": "4853271",
                        "availability": 99.98,
                        "downtimeSeconds": 12.0,
                        "buckets": [
                            {
                                "start": "2026-10-11T00:00:00.000Z",
                                "end": "2026-10-12T00:00:00.000Z",
                                "availability": 100.0,
                                "downtimeSeconds": 0.0
                            },
                            {
                                "start": "2026-10-12T00:00:00.000Z",
                                "end": "2026-10-13T00:00:00.000Z",
                                "availability": 99.5,
                                "downtimeSeconds": 12.0
                            }
                        ]
                    }
                ]
            }
        """.trimIndent()

        val history = LaterBoxApiService.parseServiceUptimeHistory(historyJson)
        assertEquals("2026-10-11T00:00:00.000Z", history.from)
        assertEquals("day", history.unit)
        assertEquals(1, history.monitors.size)

        val monitorHistory = history.monitors[0]
        assertEquals("4853271", monitorHistory.id)
        assertNotNull(monitorHistory.availability)
        assertEquals(99.98, monitorHistory.availability!!, 0.01)
        assertEquals(12.0, monitorHistory.downtimeSeconds!!, 0.01)
        assertEquals(2, monitorHistory.buckets.size)
        assertEquals(100.0, monitorHistory.buckets[0].availability!!, 0.01)
        assertEquals(99.5, monitorHistory.buckets[1].availability!!, 0.01)
    }
}
