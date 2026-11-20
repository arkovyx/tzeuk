pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: service

    property string mode: "clock"
    property date now: new Date()

    // ── Timer State ──
    property int timerSet: 0
    property int timerLeft: 0
    property bool timerOn: false
    property bool timerPaused: false
    property var timerEndTime: 0

    // ── Stopwatch State ──
    property int swMs: 0
    property bool swOn: false
    property var swStartTime: 0
    property int swElapsedBeforePause: 0

    // ── Alarm State ──
    property int alarmH: 7
    property int alarmM: 30
    property var alarmDays: []
    property bool alarmOn: false
    property bool alarmRinging: false
    property int _lastCheckedMinute: -1

    // ── Notification Process ──
    Process {
        id: notifyProcess
    }

    // ── Core Tick Timer (1s) ──
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            service.now = new Date()
            service.updateTimer()
            service.checkAlarm()
        }
    }

    // ── High-Frequency Stopwatch Timer (60fps) ──
    Timer {
        id: swTimer
        interval: 16
        running: service.swOn
        repeat: true
        onTriggered: {
            service.swMs = service.swElapsedBeforePause + (Date.now() - service.swStartTime)
        }
    }

    function updateTimer() {
        if (service.timerOn && !service.timerPaused) {
            let remaining = Math.ceil((service.timerEndTime - Date.now()) / 1000)
            if (remaining <= 0) {
                service.timerLeft = 0
                service.timerOn = false
                service.timerPaused = false
                service.timerEndTime = 0
                service.notifyUser("Timer Finished", "Your timer has completed.")
            } else {
                service.timerLeft = remaining
            }
        } else if (service.timerPaused) {
            service.timerLeft = Math.max(0, Math.ceil((service.timerEndTime - Date.now()) / 1000))
        }
    }

    function checkAlarm() {
        let d = service.now
        let currentMinute = d.getHours() * 60 + d.getMinutes()

        if (currentMinute !== service._lastCheckedMinute) {
            service._lastCheckedMinute = currentMinute

            if (service.alarmOn && !service.alarmRinging) {
                let currentDay = d.getDay()
                let dayMatch = service.alarmDays.length === 0 || service.alarmDays.indexOf(currentDay) !== -1

                if (dayMatch && d.getHours() === service.alarmH && d.getMinutes() === service.alarmM) {
                    service.alarmRinging = true
                    service.notifyUser("Alarm", "Alarm triggered!")
                }
            }
        }
    }

    function notifyUser(title, body) {
        console.log("!!! QS ALARM TRIGGERED: " + title + " - " + body + " !!!")
        let cmd = "echo 'ALARM FIRED AT $(date)' >> /tmp/qs-alarm.log && /usr/bin/notify-send -a 'tzeuk-clock' '" + title + "' '" + body + "'"
        notifyProcess.exec(["sh", "-c", cmd])
    }

    function dismissAlarm() {
        service.alarmRinging = false
        service.alarmOn = false
    }

    function timerAdd(seconds) {
        let newSet = service.timerSet + seconds
        if (newSet < 0) newSet = 0
        service.timerSet = newSet
        if (!service.timerOn) {
            service.timerLeft = newSet
        } else if (!service.timerPaused) {
            service.timerEndTime = Date.now() + (newSet * 1000)
            service.timerLeft = newSet
        }
    }

    function timerSetTo(seconds) {
        service.timerSet = seconds
        service.timerLeft = seconds
        service.timerOn = false
        service.timerPaused = false
        service.timerEndTime = 0
    }

    function timerToggle() {
        if (!service.timerOn) {
            if (service.timerLeft <= 0) service.timerLeft = service.timerSet
            service.timerEndTime = Date.now() + (service.timerLeft * 1000)
            service.timerOn = true
            service.timerPaused = false
        } else {
            service.timerPaused = !service.timerPaused
            if (!service.timerPaused) {
                service.timerEndTime = Date.now() + (service.timerLeft * 1000)
            }
        }
    }

    function timerStop() {
        service.timerOn = false
        service.timerPaused = false
        service.timerLeft = service.timerSet
        service.timerEndTime = 0
    }

    function swToggle() {
        if (!service.swOn) {
            service.swStartTime = Date.now()
            service.swOn = true
        } else {
            service.swElapsedBeforePause = service.swMs
            service.swOn = false
        }
    }

    function swReset() {
        service.swOn = false
        service.swMs = 0
        service.swElapsedBeforePause = 0
        service.swStartTime = 0
    }

    function alarmSet(h, m) {
        service.alarmH = h
        service.alarmM = m
    }

    function alarmToggleDay(dayIndex) {
        let days = service.alarmDays
        let idx = days.indexOf(dayIndex)
        if (idx >= 0) {
            days.splice(idx, 1)
        } else {
            days.push(dayIndex)
        }
        service.alarmDays = days.slice()
    }

    function alarmToggle() {
        service.alarmOn = !service.alarmOn
        if (service.alarmOn) service.alarmRinging = false
    }

    function hhmm(seconds) {
        let h = Math.floor(seconds / 3600)
        let m = Math.floor((seconds % 3600) / 60)
        let s = seconds % 60
        if (h > 0) {
            return String(h).padStart(2, "0") + ":" + String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
        }
        return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
    }

    function swFmt(ms) {
        let totalSeconds = Math.floor(ms / 1000)
        let m = Math.floor(totalSeconds / 60)
        let s = totalSeconds % 60
        let millis = ms % 1000
        return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0") + "." + String(millis).padStart(3, "0")
    }
}
