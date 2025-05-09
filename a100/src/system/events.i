                    ifnd       EVENTS_I
EVENTS_I       equ 1

EventUp        equ 1
EventDown      equ 2
EventLeft      equ 3
EventRight     equ 4
EventSelect    equ 5
EventUnselect  equ 6
EventTimer     equ 7

; characters and space use their raw key code as event-ID, so $40 (space) ist the highest ID and thus the EventCount
EventsCount    equ $40                           ; count of possible events

EventDelay     equ 10                            ; time in 1/50th of a second that must at least be between two identical events

EventQueueSize equ 16                            ; size of key buffer, must be a power of 2, below 256

                    rsreset
; do not change order of fields - when adding fields, add at the end
event_write_index:  rs.w       1
event_read_index:   rs.w       1
event_queue:        rs.b       EventQueueSize
event_size:         rs.b       0

                    endif                        ; ifnd EVENTS_I
