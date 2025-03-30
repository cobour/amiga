  ifnd     EDIT_HIGHSCORES_ASM
EDIT_HIGHSCORES_ASM equ 1

hse_init:
  rts

hse_update:
  rts

hse_process_events:
  cmp.b    #HsViewScreenEditEntry,hs_om_view_screen(a4)
  bne.s    .exit
  nop
.exit:
  rts

  ; TODO: using hs_om_new_entry_index(a4) and hs_om_new_entry_pointer(a4)
  ;       let the user enter his name
  ;       switch to HsViewScreenEditEntry when drawing of table is done
  ;       when HsViewScreenEditEntry is set, edit.asm takes control of the users input
  ;       set hs_om_save_on_exit(a4) to save

  endif                                                    ; ifnd EDIT_HIGHSCORES_ASM
