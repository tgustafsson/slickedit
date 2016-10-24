#include "slick.sh"
#import "main.e"
#include "markers.sh"

static int s_modtimeSymHighlight = -1;
static int s_markertypeSymHighlight = -1;
static int s_timerSymHighlight = -1;
static _str s_searchString = '';
static _str s_symTags[];
static int s_keyColour:[];
static boolean s_doPartialMatch = false;

int def_sym_highlight_delay = 500;
boolean def_sym_highlight_use_scrollmarkers = 1;
boolean def_sym_highlight_confirm_clear = 1;
boolean def_sym_highlight_persist_across_sessions = 0;

static struct SymColour
	{
	int m_ScrollMarkerType;
	int m_ColourSymHighlight;
	int m_cRef;	   // used for delayed color creation and selection.
	int m_rgb;
	} s_symColour[];


/*-------------------------------------------------------------------------------
	CycleSymHighlight
 
   Advances to next colour for the current word.  If current word isn't already
   highlit, goes to the least used colour
-------------------------------------------------------------------------------*/
_command void CycleSymHighlight() name_info(',')
{
	boolean isSelection;
	_str sym = GetCurWordOrSelection(isSelection);

	// if not highlit, do it.
	if (!s_keyColour._indexin(sym))
		{
		ToggleSymHighlight();
		}
	else
		{
		int iColour = s_keyColour:[sym];

		s_symColour[iColour].m_cRef -= 1;

		iColour = (iColour + 1) % s_symColour._length();
		s_keyColour:[sym] = iColour;

		s_symColour[iColour].m_cRef += 1;

		EnsureColour(iColour);

		UpdateScreen(true /* update now */)
		}
}


boolean AddToFullWordTerms(_str &sym)
{
	boolean fAdd = false;
	if (length(sym) != 0)
		{
		fAdd = true;
		for (i = 0; i < s_symTags._length();i++)
			{
			if (s_symTags[i] == sym)
				{
				fAdd = false;
				s_symTags._deleteel(i);
				break;
				}
			}
		if (fAdd)
			{
			int cTags = s_symTags._length();
			s_symTags[cTags] = sym;
			s_symTags._sort("D");
			if (s_symTags._length() != cTags + 1)
				{
				say("Failed to add tag: " :+ sym);
				}
			}
		if (s_symTags._length() > 0)
			{
			s_searchString = _escape_re_chars(s_symTags[0], 'U');
			for (i = 1; i < s_symTags._length(); i++)
				{
				s_searchString :+= '|' :+ _escape_re_chars(s_symTags[i], 'U');
				}
			}
		else
			{
			s_searchString = '';
			_StreamMarkerRemoveType (p_window_id, s_markertypeSymHighlight);
			RemoveSymHighlightMarkers(p_window_id);
			} 
		}
	return fAdd;

}

void RemoveSymFromColourList(_str &sym)
{
	int index = s_keyColour:[sym];
	if (index < 0 || index > s_symColour._length())
		{
		say("bad index in keycolour for: " :+sym);
		}
	else
		{
		if (index > s_symColour._length())
			{
			say("bad index for symColour (index/sym): ":+index:+"/":+sym);
			}
		else if (s_symColour[index].m_cRef <= 0)
			{
			say("bad cRef in symColour when deleting: " :+ sym);
			}
		else
			{
			s_symColour[index].m_cRef -= 1;
			s_keyColour._deleteel(sym);
			}
		}
}


_str GetCurWordOrSelection(boolean &isSelection)
{
	int start_col, end_col;
	_str sym;

	isSelection = false;
	if (_select_type() == "CHAR")
	 {
	 int dummy;
	 _str dummy2;
	 int numLines;
	 _get_selinfo(start_col, end_col, dummy, '', dummy2, dummy, dummy, numLines);
	 if (numLines == 1 && start_col != end_col)
		 {
		 _str line;
		 sym = _expand_tabsc(start_col, end_col - start_col, 'S');
		 isSelection = true;
		 }
	 }

	if (!isSelection)
		sym = cur_word(start_col);

	return sym;

}

_command void ToggleSymHighlightFullMatch() name_info(',')
{
	s_doPartialMatch = !s_doPartialMatch;
	UpdateScreen(true);
}

/* T O G G L E  S Y M  H I G H L I G H T */
/*----------------------------------------------------------------------------
	%%Function: ToggleSymHighlight
	%%Author: MarkSun
	%%Owner: MarkSun

   If the IP is on an identifier, either add it or remove it from the list
   of identifiers we're tracking for highlighting purposes.

----------------------------------------------------------------------------*/
_command void ToggleSymHighlight() name_info(',')
{
	int i;
	_str sym;
	boolean isPartial = false;

	sym = GetCurWordOrSelection(isPartial);

	boolean fAdded;

	fAdded = AddToFullWordTerms(sym);

	UpdateScreen(true /* update now */);

	if (!fAdded && s_keyColour._indexin(sym))
		{
		RemoveSymFromColourList(sym);
		}
	else if (!fAdded)
		{
		say("Failed to remove keycolour for: ":+sym);
		}

}

/*-------------------------------------------------------------------------------
	_InitSymColour
-------------------------------------------------------------------------------*/
static void _InitSymColour()
{
   if (!def_sym_highlight_persist_across_sessions || s_symColour._length() == 0)
   {
   	s_symColour[0].m_cRef = 0;
   	s_symColour[1].m_cRef = 0;
   	s_symColour[2].m_cRef = 0;
   	s_symColour[3].m_cRef = 0;
   	s_symColour[4].m_cRef = 0;
   }
   s_symColour[0].m_ColourSymHighlight = -1;
   s_symColour[0].m_rgb = _rgb(0x00, 0xff, 0xff);
   s_symColour[1].m_ColourSymHighlight = -1;
   s_symColour[1].m_rgb = _rgb(0xff, 0x00, 0xff);
   s_symColour[2].m_ColourSymHighlight = -1;
   s_symColour[2].m_rgb = _rgb(0xff, 0x00, 0x00);
   s_symColour[3].m_ColourSymHighlight = -1;
   s_symColour[3].m_rgb = _rgb(0x00, 0xff, 0x00);
   s_symColour[4].m_ColourSymHighlight = -1;
   s_symColour[4].m_rgb = _rgb(0xff, 0xff, 0x00);

   if (def_sym_highlight_persist_across_sessions)
   {
      int i;
      for (i=0; i < s_symColour._length(); i++)
      {
         if (s_symColour[i].m_cRef > 0)
         {
            EnsureColour(i);
         }
      }
   }
}


/*-------------------------------------------------------------------------------
	DbgDumpSymHighlight
 
   Dumps out current array values for debugging purposes
-------------------------------------------------------------------------------*/
_command void DbgDumpSymHighlight() name_info(',')
{
	int i;
	say ("--- SymHighlight dump: " :+ _time('L'));
	say ("search string:");
	say ("   " :+ s_searchString);
	say ("word list:");
	for (i = 0; i < s_symTags._length(); i++)
		{
		say ("   " :+ (i+1) :+ ": " :+ s_symTags[i]);
		}

	say ("Colours index for words:");
	for (i = 0; i < s_symTags._length(); i++)
		{
		if (s_keyColour._indexin(s_symTags[i]))
			{
			say ("   " :+ s_symTags[i] :+ ": " :+ s_keyColour:[s_symTags[i]] + 1);
			}
		else
			{
			say ("   " :+ s_symTags[i] :+ ": no current colour");
			}
		}
	say ("colour cRefs:");
	for (i = 0; i < s_symColour._length(); i++)
		{
		say ("   " :+ (i + 1) :+ ": " :+ s_symColour[i].m_cRef);
		}


	say ("--- End SymHighlight dump");

}


/*-------------------------------------------------------------------------------
	DoClearAllSymHighlightStructs
-------------------------------------------------------------------------------*/
void DoClearAllSymHighlightStructs()
{
	int i;
	s_symTags._makeempty();
	s_searchString = '';
	for (i = 0; i < s_symColour._length(); i++)
		{
		if (s_symColour[i].m_cRef > 0)
			{
			s_symColour[i].m_cRef = 0;
			}
		}
	s_keyColour._makeempty();
}


/* C L E A R  A L L  S Y M  H I G H L I G H T */
/*----------------------------------------------------------------------------
	%%Function: ClearAllSymHighlight
	%%Author: MarkSun
	%%Owner: MarkSun

   Bring up a dialog listing all identifiers that we are currently highlighting.
   If you respond Yes, then clear the entire list.

----------------------------------------------------------------------------*/
_command void ClearAllSymHighlight() name_info(',')
{

	_str result = IDYES;
	_str messageString = "Clear the following list?\n\n";
	int i;
	int j;

	if (def_sym_highlight_confirm_clear)
	{
		for (i = 0; i < s_symTags._length(); i++)
			{
			messageString :+= (i+1) :+ ": " :+ s_symTags[i] :+ "\n";
			}

		result=_message_box(messageString, '', MB_YESNO|MB_ICONQUESTION);
	}

	if (result==IDYES)
		{
		DoClearAllSymHighlightStructs();
		UpdateScreen(true);
		}
}


/*-------------------------------------------------------------------------------
	RemoveSymHighlightMarkers
-------------------------------------------------------------------------------*/
void RemoveSymHighlightMarkers(int wid)
{
	iMac = s_symColour._length();

	for (i = 0; i < iMac; i++)
		{
		_ScrollMarkupRemoveType(wid, s_symColour[i].m_ScrollMarkerType);
		}
}

/*-------------------------------------------------------------------------------
	RemoveAllSymHighlightMarkerTypes
-------------------------------------------------------------------------------*/
void RemoveAllSymHighlightMarkerTypes()
{
	iMac = s_symColour._length();

	for (i = 0; i < iMac; i++)
		{
		_ScrollMarkupRemoveAllType(s_symColour[i].m_ScrollMarkerType);
		}
}


/*-------------------------------------------------------------------------------
	_UpdateWindow
-------------------------------------------------------------------------------*/
void _UpdateWindow()
{
	typeless p,m,ss,sf,sw,sr,sf2;
	_save_pos2(p);
	save_selection(m);
	save_search(ss, sf, sw, sr, sf2);
	_StreamMarkerRemoveType (p_window_id, s_markertypeSymHighlight);
	RemoveSymHighlightMarkers (p_window_id);


	if (s_symTags._length() != 0)
		{
		_str searchArgs;
		if (s_doPartialMatch)
		{
			searchArgs = '<U@XC';
		}
		else
		{
			searchArgs = 'W<U@XC';
		}
		_deselect();
		top();
		if ( !search(s_searchString, searchArgs) )
			{
			do
				{
				s = strip( get_text( match_length(), (int)_QROffset() ), 'T' );
				long offset_highlight = _QROffset();
				int length_Highlight = s._length();
				int pos_marker = _StreamMarkerAdd( p_window_id, offset_highlight, length_Highlight, true, 0, s_markertypeSymHighlight, '');
				_StreamMarkerSetTextColor(pos_marker, GetSymHighlightColour(s));
				if (def_sym_highlight_use_scrollmarkers)
					{
					int line=(int)_QLineNumberFromOffset(offset_highlight);
					_ScrollMarkupAdd(p_window_id, line, GetSymHighlightMarker(s));
					}
				}
			while (!repeat_search(searchArgs));
			}
		}

	restore_search( ss, sf, sw, sr, sf2); 
	restore_selection(m);
	_restore_pos2(p);

	refresh();
}


/* U P D A T E  S C R E E N */
/*----------------------------------------------------------------------------
	%%Function: UpdateScreen
	%%Author: MarkSun
	%%Owner: MarkSun

   Goes through the current buffer and update the highlights based on current
   information.

----------------------------------------------------------------------------*/
static void UpdateScreen(boolean fNow)
{
	get_window_id( auto orig_view);
	activate_window (_mdi.p_child);

	if (s_modtimeSymHighlight != p_LastModified || fNow)
		{
		s_modtimeSymHighlight = p_LastModified;

		for_each_mdi_child('-UpdateWindow','');
		}
	activate_window(orig_view); 
}


/* S Y M  H I G H L I G H T  C A L L B A C K */
/*----------------------------------------------------------------------------
	%%Function: SymHighlightCallback
	%%Author: MarkSun
	%%Owner: MarkSun

	Callback to periodically ensure the current buffer has been updated.

----------------------------------------------------------------------------*/
void SymHighlightCallback()
{
	if ( !p_mdi_child || command_state())
		{
		return;
		}
	if (_idle_time_elapsed() < def_sym_highlight_delay)
		{
		return;
		}

	UpdateScreen(false /* update now */);
}


/*-------------------------------------------------------------------------------
	EnsureColour
-------------------------------------------------------------------------------*/
static void EnsureColour(int iColour)
{
	if (s_symColour[iColour].m_ColourSymHighlight == -1)
		{
		s_symColour[iColour].m_ColourSymHighlight = _AllocColor();
		_default_color(s_symColour[iColour].m_ColourSymHighlight, _rgb(0x00, 0x00, 0x00), s_symColour[iColour].m_rgb, 0);
		s_symColour[iColour].m_ScrollMarkerType = _ScrollMarkupAllocType();

		_ScrollMarkupSetTypeColor(s_symColour[iColour].m_ScrollMarkerType, s_symColour[iColour].m_ColourSymHighlight);
		}
}

/*-------------------------------------------------------------------------------
	IGetNextSymColour
-------------------------------------------------------------------------------*/
static int IGetNextSymColour()
{
	int i, iMac;
	int iTarget = 0, iTargetVal = s_symColour[0].m_cRef;

	iMac = s_symColour._length();

	if (iTargetVal != 0)
		{
		for (i = 1; i < iMac; i++)
			{
			if (s_symColour[i].m_cRef < iTargetVal)
				{
				iTargetVal = s_symColour[i].m_cRef;
				iTarget = i;
				if (iTargetVal == 0)
					break;
				}
			}
		}
	s_symColour[iTarget].m_cRef += 1;
	EnsureColour(iTarget);
	if (iTarget < 0 || iTarget >= iMac)
		{
		say ("Bad colour index returned in IGetNextSymColour: ":+iTarget);
		}
	return iTarget;

}


/* G E T  S Y M  H I G H L I G H T  C O L O U R */
/*----------------------------------------------------------------------------
	%%Function: GetSymHighlightColor
	%%Author: Setup the highlighting colour
	%%Owner: Setup the highlighting colour

	

----------------------------------------------------------------------------*/
static int GetSymHighlightColour(_str &strKey)
{
	if (!s_keyColour._indexin(strKey))
		{
		s_keyColour:[strKey] = IGetNextSymColour();
		}
	else if (s_keyColour:[strKey] < 0 || s_keyColour:[strKey] >= s_symColour._length())
		{
		say ("index for '":+strKey:+"' out of range: ":+s_keyColour:[strKey]);
		s_keyColour:[strKey] = IGetNextSymColour();
		}
	else if (s_symColour[s_keyColour:[strKey]].m_cRef == 0)
		{
		say ("Hit recovery code in GetSymHighlightColour");
		s_keyColour:[strKey] = IGetNextSymColour();
		}


	return s_symColour[s_keyColour:[strKey]].m_ColourSymHighlight;   
}

/*-------------------------------------------------------------------------------
	GetSymHighlightMarker
-------------------------------------------------------------------------------*/
static int GetSymHighlightMarker(_str &strKey)
{
	if (!s_keyColour._indexin(strKey))
		{
		s_keyColour:[strKey] = IGetNextSymColour();
		}
	else if (s_keyColour:[strKey] < 0 || s_keyColour:[strKey] >= s_symColour._length())
		{
		say ("index for '":+strKey:+"' out of range: ":+s_keyColour:[strKey]);
		s_keyColour:[strKey] = IGetNextSymColour();
		}
	else if (s_symColour[s_keyColour:[strKey]].m_cRef == 0)
		{
		say ("Hit recovery code in GetSymHighlightColour");
		s_keyColour:[strKey] = IGetNextSymColour();
		}


	return s_symColour[s_keyColour:[strKey]].m_ScrollMarkerType;   
}


/* D E F E R R E D  I N I T  S Y M  H I G H L I G H T */
/*----------------------------------------------------------------------------
	%%Function: DeferredInitSymHighlight
	%%Author: MarkSun
	%%Owner: MarkSun

   Start up our callback function.
   I do not know why deferring the init is good, I copied this from another
   macro.

----------------------------------------------------------------------------*/
static void DeferredInitSymHighlight()
{

	if ( !pos( "-mdihide", _editor_cmdline, 1, 'i' ) )
		{

		if ( s_markertypeSymHighlight < 0 )
			{
			s_markertypeSymHighlight = _MarkerTypeAlloc();
			}
		else
			{
			_StreamMarkerRemoveAllType( s_markertypeSymHighlight );
			RemoveAllSymHighlightMarkerTypes();
			}

		if ( s_timerSymHighlight >= 0 )
			_kill_timer( s_timerSymHighlight );

      _InitSymColour();
      if (!def_sym_highlight_persist_across_sessions)
      {
         DoClearAllSymHighlightStructs();
      }
		s_timerSymHighlight = _set_timer( def_sym_highlight_delay, SymHighlightCallback );
		}
}


/* D E F I N I T */
/*----------------------------------------------------------------------------
	%%Function: definit
	%%Author: MarkSun
	%%Owner: MarkSun

	Initialize this module.

----------------------------------------------------------------------------*/
definit()
{
	s_modtimeSymHighlight = -1;

	if (arg(1) != 'L')
		{
		s_timerSymHighlight = -1;
		s_markertypeSymHighlight = -1;
		}

	_post_call( DeferredInitSymHighlight );
}

_exit_cleanup()
{
   int i;
   for (i=0; i < s_symColour._length(); i++)
   {
      if (s_symColour[i].m_ColourSymHighlight != -1)
      {
         _FreeColor(s_symColour[i].m_ColourSymHighlight);
      }
   }

}
