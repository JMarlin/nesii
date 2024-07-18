.segment "CALL_MAP"
.include "fs.inc"
.include "binary_loader.inc"

;$07ee
jmp fs_scan_catalog
;$07f1
jmp fs_find_file
;07f4
jmp fs_open_file
;07f7
jmp fs_read_file_byte
;07fa
jmp binary_loader_load