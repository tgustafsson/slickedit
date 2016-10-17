//This macro has been posted for other SlickEdit users to use and explore.
//Depending on the version of SlickEdit that you are running, this macro may or may not load.
//Please note that these macros are NOT supported by SlickEdit and is not responsible for user submitted macros.

/*=======================================================================*
 |   file name : _glisp.e
 |-----------------------------------------------------------------------*
 |   function  :
 |-----------------------------------------------------------------------*
 |   author    : Gregg Tavares
 *=======================================================================*/

 /*

     This is an attempt to do some of the auto-formatting for lisp
     that emacs does because basically it's nearly impossible to
     program in lisp unless you have the editor help you by forcing
     your formatting and as I hate emacs I needed to get slickedit
     to do this for me.

     To get it to work, make a new file extension and change the name of the
     macros below that start with "el_" to match your extension.  For example
     if your extention is ".foo" then rename those functions from "el_proc_search"
     to "foo_proc_search" and el_tag_case to foo_tag_case.  This will allow
     slickedit to make tags for lisp.  Of course you could just use the ".el"
     extension.

     The problem is, lisp is so macro oriented that unless the editor actually
     understands lisp there is really no way for it to know what's a function
     so you need to define your macros in the list below called LISP_COMMON_LIST
     and below that in el_proc_search you may have adjust the switch statement
     to tell slickedit what your various new keywords mean.

     Otherwise:

     with a file using your new extension loaded into the current window,
     pick "Tools/Configuration/Key Bindings...", UNcheck "Affect All Modes"
     and assign the following keys

     Enter    ->  glisp_enter
     Tab      ->  glisp_tapitifnoneleft
     Ctrl-X   ->  glisp_pasteandtabit (or any other key you want paste on)

     you can also assign glisp_tabitanddown to any key that you want to be
     able to press repeatedly to reformat an area.

     note: that if you assign the above keys you can select an area
           and press Tab and it will reformat the selecltion.

     note: If you forget to uncheck "Affect All Modes" you will mess up editing
           other files.

     As for how it formats if you look below at "glist_tab_table" you can add
     new keywords to format things certain ways.  For example the entry for "if"

        "if"              => "4 4 2",

     means indent the first argument 4 characters, the next 4 and the last 2.
     so it would be formatted like this

        (if (> a b)
            (do thing 1)
          (do thing 2)
          )

     The default is to line up things after the first word so for example

        (foobar test
                arg1
                arg2
                arg3
                )

     otherwise a comments are formated based on the following

         ;        = comment, start at column 81 (slickedit columns start at 1, emacs starts at 0)
         ;;       = align with rest of code
         ;;;      = same as ;;
         ;;;;     = first column
         ;*       = first column

 */

#include "slick.sh"

#define LISP_COMMON_LIST \
   ' defconstant' \
   ' defun'       \
   ' defun-extern'\
   ' deftype'     \
   ' define'      \
   ' defmacro'    \
   ' defmethod'   \
   ' defstate'    \
   ' defbehavior' \
   ' defbehavior-extern' \
   ' defsurf'     \
   ' define-perm' \
   ' defbitlist'  \
   ' defenum'     \
   ' debug-defun' \
   ' debug-defun-extern' \
   ' def' \
   ' defn' \
   ' ns' \
   ''
#define WHITESPACE       '[\x9\x20\n]'

_str el_tag_case()
{
   return "e"
}

int el_proc_search (_str &proc_name, int find_first)
{
   proc_was_null=0
   if ( proc_name:=='' )
   {
      proc_was_null=1
      proc_name='[A-Za-z\!\$\%\&\*\+\-\.\/\:\<\=\>\?\@\^\_\~][A-Za-z0-9\!\$\%\&\*\+\-\.\/\:\<\=\>\?\@\^\_\~]#'
   }
   else
   {
   }

   if ( find_first )
   {
      if (proc_was_null)
      {
         search_key='~\x27\((':+stranslate(strip(LISP_COMMON_LIST),'|',' '):+")":+WHITESPACE:+'~\x27~,';
         //messageNwait ("search_key=(" :+ search_key :+ ")");
      }
      else
      {
         //messageNwait ("proc search (" :+ proc_name :+ ")");
         search_key='\((':+stranslate(strip(LISP_COMMON_LIST),'|',' '):+")":+WHITESPACE:+proc_name:+WHITESPACE;
         //messageNwait (search_key);
      }
      notFound = search (search_key,'@reXCS');
   }
   else
   {
      notFound = repeat_search ('@reXCS');
   }

   if (!notFound)
   {
      get_line line;
//      messageNwait ("ln=" :+ line)
      line = expand_tabs(line);
      line = substr (line, p_col);
//      messageNwait ("ln2=" :+ line)
      parse line with ptype pname .;

      switch (ptype)
      {
      case "(define":
         tagtype = "(define)";
         break;
      case "(defconstant":
         tagtype = "(constant)";
         break;
      case "(defenum":
         tagtype = "(enum)";
         break;
      case "(deftype":
      case "(defbitlist":
      case "(defsurf":
         tagtype = "(typedef)";
            break;
      case "(defmacro":
      case "(define-perm":
         tagtype = "(define)";
         break;
      default:
         tagtype = "(procfunc)";
         break;
      }
//      messageNwait ("pt=" :+ ptype :+ " pn=" :+ pname);
      proc_name = pname :+ tagtype;
//      messageNwait ("pn=" :+ proc_name);
   }

//   messageNwait ("return = (" :+ proc_name :+ ")");
   return (notFound);
}

/***********************************  ************************************/
/***********************************  ************************************/
/***********************************  ************************************/

_str strip_comments (_str line)
{
   int stringLevel = 0;
   int len = length (line);

   i = 1;
   while (i <= len)
   {
      c = substr(line,i,1);
      if (stringLevel == 0)
      {
         if (c == ';')
         {
            return (substr (line, 1, i-1));
         }
         else if (c :== '"' && (i <= 1 || substr(line,i-1,1) != '~'))
         {
            //messageNwait ("found str at i=" :+ i :+ ":ln='" :+ line :+ "'")
            stringLevel++;
         }
      }
      else
      {
         if (c :== '"' && (i <= 1 || substr(line,i-1,1) != '~'))
         {
            //messageNwait ("found end at i=" :+ i :+ ":ln='" :+ line :+ "'")
            stringLevel--;
         }
      }
      i++;
   }

   return line;
}

// how to tab based on certain things
//
// the default is to indent to just after the first keyword
// <number> = how many tabs to indent from parent (
// ;        = comment, start at column 81 (slickedit columns start at 1, emacs starts at 0)
// ;;       = align with rest of code
// ;;;      = same as ;;
// ;;;;     = first column
// ;*       = first column
// arg1     = align with first argument

static _str glisp_tab_table:[]=
{
   "begin"           => "2",
   "block"           => "2",
   "case"            => "2",
   "cond"            => "2",
   "#cond"           => "2",
   "countdown"       => "2",
   "dotimes"         => "2",
   "defconstantgroup"=> "2",
   "defbitlist"      => "2",
   "defenum"         => "2",
   "define"          => "2",
   "defmacro"        => "2",
   "defmethod"       => "2",
   "defstate"        => "2",
   "deftype"         => "2",
   "defun"           => "2",
   "def"             => "2",
   "defn"            => "2",
   "defun-extern"    => "2",
   "defsfun"         => "2",
   "dolist"          => "2",
   "enum-case-num"   => "2",
   "handler"         => "2",
   "if"              => "4 4 2",
   "lambda"          => "2",
   "let"             => "2",
   "let*"            => "2",
   "main"            => "1",
   "main-group"      => "1",
   "menu"            => "1",
   "mlet"            => "2",
   "mlet*"           => "2",
   "unless"          => "2",
   "until"           => "2",
   "while"           => "2",
   "with-gensyms"    => "2",
   "with-open-file"  => "2",
   "with-open-bfile" => "2",
   "with-profile-band"=>"2",
   "with-rept-rand"  => "2",
   "with-res-tag-get"=> "2",
   "when"            => "2",
   ";"               => ";",
};

// indent this line to the "correct" level
_command glisp_tabit() name_info(','MARK_ARG2|TEXT_BOX_ARG2|EDITORCTL_ARG2)
{
   // don't do anything if this line starts with ( and is in first column || ';'
   get_line(line);

//   if (substr(line,1,1) != '(' && substr(line,1,1) != ';')
   {
      typeless oldpos;

      // save the current position (why, I don't know)
      _save_pos2(old_pos);

      // look backward until you find the first unmatched paren open paren
      // QUESTION: should we stop at a open paren in column 0?
      up;
      parenbal               = 0;
      stoplooking            = FALSE;
      found                  = FALSE;
      foundAt                = 0;
      whiteOnlyBetween       = TRUE;
      lastNonWhiteAfterWhite = 0;
      wasOnWhite             = TRUE;
      indentTo               = 1;
      argCount               = 0;
      doDefault              = TRUE;
      commentLevel           = 0;
      stringLevel            = 0;


      // check for comments
      {
         start = strip (line, 'L');
         len   = length(start);
         if (len >= 4 && substr(start, 1, 4) == ";;;;")
         {
            doDefault   = FALSE;
            stoplooking = TRUE;
            indentTo    = 0;
         }
         else if (len >= 3 && substr(start, 1, 3) == ";;;")
         {
         }
         else if (len >= 2 && substr(start, 1, 2) == ";;")
         {
         }
         else if (len >= 2 && substr(start, 1, 2) == ";*")
         {
            doDefault   = FALSE;
            stoplooking = TRUE;
            indentTo    = 0;
         }
         else if (len >= 1 && substr(start, 1, 1) == "*")
         {
            doDefault   = FALSE;
            stoplooking = TRUE;
            indentTo    = 0;
         }
         else if (len >= 1 && substr(start, 1, 1) == ";")
         {
            doDefault   = FALSE;
            stoplooking = TRUE;
            indentTo    = 81 - 1;
         }
      }

      while (!stoplooking)
      {
         get_line(line);

         // strip comments
         line = strip_comments (line);

         // strip trailing whitespace
         line = strip (line, "T");

//         messageNwait ("->"line"<-");

         // expand it so it looks like it's displayed
         line = expand_tabs(line);

         // start at end of line
         i = length (line);
         //messageNwait ("line='" :+ line :+ "'");
         while (i > 0)
         {
            c = substr(line,i,1);

   //         messageNwait ("c='":+c:+"':i=":+i);
            if (commentLevel == 0 && stringLevel == 0)
            {
               if (c :== ' ' || c :== '\t')
               {
                  if (!wasOnWhite)
                  {
                     if (parenbal == 0)
                     {
                        argCount++;
                     }
                     lastNonWhiteAfterWhite = i;
      //               messageNwait("lastNo.. =" :+ lastNonWhiteAfterWhite);
                  }
                  wasOnWhite = TRUE;
      //            messageNwait("wasOnWhite = TRUE");
               }
               // check for comments
               else if (c :== '#' && i > 1 && substr(line,i-1,1) :== '|')
               {
                  commentLevel++;
               }
               // check for strings
               else if (c :== '"' && (i <= 1 || substr(line,i-1,1) != '~'))
               {
                  // if there is nothing but whitespace before this
                  // quote then end our search here
                  // unless this is a double quote on a line by itself
                  //
                  //messageNwait("pos=" :+ pos ('~( |\t)', substr(line,1,i-1),1,'R') :+ ":l='" :+ substr(line,1,i-1) :+ "':len=" :+ (length (substr(line,1,i-1))));
                  int pos_of_nonwhite;

                  pos_of_nonwhite = pos ('~(\t| )', substr(line,1,i-1),1,'R');

                  if (pos_of_nonwhite == 0 || pos_of_nonwhite > i - 1)
                  {
                     if (length(substr(line,i+1)))
                     {
                        stoplooking = TRUE;
                        found       = FALSE;
                        lastNonWhiteAfterWhite = i;
                        //messageNwait ("break early" :+ i);
                        break;
                     }
                  }
                  stringLevel++;
                  //messageNwait ("found string at i=" :+ i);
               }
               else
               {
                  wasOnWhite = FALSE;
      //            messageNwait("wasOnWhite = FALSE");
               }

               if (c :== ')')
               {
                  parenbal++;
               }
               else if (c :== '(')
               {
                  parenbal--;
                  if (parenbal < 0)
                  {
                     stoplooking = TRUE;
                     found       = TRUE;
                     foundAt     = i;
                     break;
                  }
                  lastNonWhiteAfterWhite = 0;
            //      messageNwait ("TRUE:i=":+i);
                  whiteOnlyBetween = TRUE;
               }
               else if (c != ' ' && c != '\t')
               {
                  whiteOnlyBetween = FALSE;
            //      messageNwait ("FALSE:i=":+i);
               }
            }
            else if (stringLevel)
            {
               // skip strings
               if (c :== '"')
               {
                  //messageNwait ("i=" :+ i :+ ":char='" :+ substr(line,i-1,1) :+ "'");
                  if (i <= 1 || substr(line,i-1,1) != '~')
                  {
                     stringLevel--;
                     //messageNwait ("exit string at i=" :+ i);
                  }
               }
            }
            else
            {
               // skip comments
               if (c :== '#' && i > 1 && substr(line,i-1,1) :== '|')
               {
                  commentLevel++;
               }
               else if (c :== '|' && i > 1 && substr(line,i-1,1) :== '#')
               {
                  commentLevel--;
               }
            }
            i--;
         }

         if (!found && !stoplooking)
         {
            lastNonWhiteAfterWhite = 0;
            wasOnWhite             = TRUE;
            if (length(line) > 0 && substr(line,1,1) :== '(')
            {
           //    messageNwait ("hit ( at start");
          //     found   = TRUE;
               foundAt = 0;
               break;
            }
            up;
            if (p_line == 0)
            {
               message ("HIT TOP OF FILE.");
               _restore_pos2(old_pos);
               return (0);
            }
         }
      }
      last_line = p_line;

      _restore_pos2(old_pos);
      _begin_line();

      // if we found one then see if it matches a keyword
      if (found)
      {
         restOfLine = substr(line, foundAt + 1);

         parse restOfLine with funcName .;
         //message("1)args="argCount":at="foundAt":wob="whiteOnlyBetween":lnwaw="lastNonWhiteAfterWhite":fnm=["funcName"]:pline="last_line);

         if (glisp_tab_table._indexin(funcName))
         {
            argNum  = argCount;
            tabSpec = glisp_tab_table:[funcName];
            tabWork = tabSpec;

            doDefault = FALSE;

            // find spec for arg #
            argNum++;
            while (argNum)
            {
               tabOption = _parse_line(tabWork,' ');
               if (!length (tabWork))
               {
                  break;
               }
               argNum--;
            }

            if (tabSpec :== ';')
            {
            }
            else if (tabSpec :== 'arg1')
            {
               if (lastNonWhiteAfterWhite != 0)
               {
                    indentTo = lastNonWhiteAfterWhite;
               }
               else
               {
                  doDefault = TRUE;
               }
            }
            else
            {
               #if 0
               message(
                  "2)args=":+argCount:+
                  ":at=":+foundAt:+
                  ":lnwaw=":+lastNonWhiteAfterWhite:+
                  ":fnm=":+funcName:+
                  ":tspc=":+tabSpec:+
                  ":topt=":+tabOption:+
                  ""
                  );
               #endif
               indentTo = foundAt - 1 + tabOption;
               #if 0
               message(
                  "3)args=":+argCount:+
                  ":at=":+foundAt:+
                  ":lnwaw=":+lastNonWhiteAfterWhite:+
                  ":fnm=":+funcName:+
                  ":tspc=":+tabSpec:+
                  ":topt=":+tabOption:+
                  ":i-to=":+indentTo:+
                  ""
                  );
               #endif
            }
         }
      }
      else
      {
      //   message ("not found");
      }

      if (doDefault)
      {
         indentTo = foundAt;

         if (lastNonWhiteAfterWhite != 0)
         {
//            messageNwait("END!:lastNo.. =" :+ lastNonWhiteAfterWhite);
            indentTo = lastNonWhiteAfterWhite;  // indent to first arg
         }
         else
         {
            if (!whiteOnlyBetween /* && !argCount && found */)
            {
//               message ("wob = FALSE")
               indentTo++;
            }
            else
            {
//               message ("wob = TRUE")
            }
         }

//         message("ind="indentTo":fat="foundAt);
      }

      get_line(curline);
      curline = strip (curline, 'L');
      replace_line(indent_string(indentTo) :+ curline);
   }
}

void glisp_gototab ()
{
   get_line(line);
   line = expand_tabs(line);
   nonspace = pos('[~ \t]', line, 1, 'R');
   if (nonspace)
   {
      p_col = nonspace;
   }
   else
   {
      end_line();
   }
}
_command glisp_enter() name_info(','MARK_ARG2|TEXT_BOX_ARG2|EDITORCTL_ARG2)
{
   if (!command_state() && p_mode_name :== 'gc')
   {
      typeless p;
      maybe_split_insert_line();
      up();
      glisp_tabit();
      down();
      glisp_tabit();
      glisp_gototab();
   }
   else
   {
      maybe_split_insert_line();
   }
}

_command glisp_tabitanddown() name_info(','MARK_ARG2|TEXT_BOX_ARG2|EDITORCTL_ARG2)
{
   glisp_tabit();
   cursor_down();
}

_command glisp_tabitifnoneleft() name_info(','MARK_ARG2|TEXT_BOX_ARG2|EDITORCTL_ARG2)
{
   if (!command_state() && p_mode_name :== 'gc')
   {
      if (_get_selinfo (junk_col, junk_ecol, junk_buf_id) == TEXT_NOT_SELECTED_RC)
      {
         fTabit = FALSE;
         get_line(line);
         line = expand_tabs(line);
         if (pos('[~ \t]', line, 1, 'R') == 0)
         {
            fTabit = TRUE;
         }
         else
         {
            cutpoint = min(p_col - 1, length(line));
            line     = substr(line,1,cutpoint);
      //      message ("("line")");
            if (!pos('[~ \t]', line, 1, 'R'))
            {
               fTabit = TRUE;
            }
         }
         if (fTabit)
         {
            glisp_tabit();
            glisp_gototab();
         }
         else
         {
            brief_tab();
         }
      }
      else
      {
         if (_select_type()=='LINE' || _select_type()=='CHAR')
         {
            typeless p;

            markid=arg(1);

            _save_pos2(p);
            _begin_select(markid);
            first_line=p_line;
            _end_select(markid);
            last_line=p_line;

            for (line=first_line; line<=last_line; line++)
            {
               p_line = line;
               p_col  = 1;
               glisp_tabit ();
            }

            _restore_pos2(p);
         }
         else
         {
            brief_tab();
         }
      }
   }
   else
   {
      brief_tab();
   }

}

_command glisp_pasteandtabit() name_info(','MARK_ARG2|TEXT_BOX_ARG2|EDITORCTL_ARG2)
{
   if (!command_state() && p_mode_name :== 'gc' && clipboard_itype(0)=='LINE')
   {
      typeless p;

      first_line = p_line;
      brief_paste();
      last_line = p_line;

      _save_pos2(p);
      for (line=first_line; line<=last_line; line++)
      {
         p_line = line;
         p_col  = 1;
         glisp_tabit ();
      }
      _restore_pos2(p);
   }
   else
   {
      brief_paste();
   }
}


