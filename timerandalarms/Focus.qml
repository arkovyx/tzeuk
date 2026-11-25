pragma Singleton
import QtQuick
import "."

QtObject {
    readonly property bool running: ClockService.timerOn && !ClockService.timerPaused
    readonly property bool paused:  ClockService.timerOn && ClockService.timerPaused
    readonly property real left:    ClockService.timerOn ? ClockService.timerLeft : ClockService.timerSet
    readonly property int minutes:  Math.round(ClockService.timerSet / 60)
    readonly property real f: {
        if (!ClockService.timerOn) return 0
        return 1.0 - (ClockService.timerLeft / Math.max(1, ClockService.timerSet))
    }
    function set(m)  { ClockService.timerSetTo(m * 60) }
    function toggle() {
        if (!ClockService.timerOn) ClockService.timerStart()
        else ClockService.timerToggle()
    }
    function reset() { ClockService.timerStop() }
    function mmss(sec) { return ClockService.hhmm(sec) }
}
