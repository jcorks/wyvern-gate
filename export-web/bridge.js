mergeInto(LibraryManager.library, {
  external_on_start_commit: function() {
    WYRVEN_startCommit();
  },
  
  external_on_commit_text: function(text) {
    WYRVEN_onCommitText(UTF8ToString(text));
  },
  
  external_on_end_commit: function() {
    WYRVEN_onEndCommit();
  },
  
  external_on_save_state: function(slot, str) {
    WYRVEN_onSaveState(slot, UTF8ToString(str));
  },
  
  external_on_load_state: function(slot) {
    return allocate(intArrayFromString(WYRVEN_onLoadState(slot)), 'i8', ALLOC_NORMAL);
  },

  external_get_input: function() {
    return WYRVEN_getInput();
  },
  
  external_unhandled_error: function(version, error) {
    return WYRVEN_error(
        UTF8ToString(version),
        UTF8ToString(error)
    );
  }
});
