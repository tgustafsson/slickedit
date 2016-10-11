#pragma option(strictsemicolons,on)
#pragma option(strictparens,on)
/*
   Support Functions for various assembly languages including:

      Intel/Windows NASM or MASM
      Unix Assemblers for Intel, SPARC, MIPS, HP, or PPC
      System/390 Assembler

   This support is dynamically loaded.
*/
#include 'slick.sh'
#include 'tagsdb.sh'
#define MODE_NAME 'TeX'
#define EXTENSION 'tex'
#define MASM_MODE_NAME 'TeX'
#define ID_CHARS 'A-Za-z0-9'
// called when ASM module is loaded
// sets up extensions for native assembler, ASM390 Assembler, and Unix Assembly
defload()
{
   _str setup_info;
   _str compile_info='';
   _str syntax_info;
   _str be_info='';

   // Intel/Windows Assembler
   setup_info='MN='MODE_NAME',TABS=+8,MA=1 74 1,':+
              'KEYTAB=default-keys,WW=0,IWT=0,ST=0,IN=1,':+
              'WC='ID_CHARS',LN=tex,CF=1,';
   syntax_info='8 1 1 0 4 1 0';
   be_info='';
   _CreateLanguage(EXTENSION,'',MODE_NAME,setup_info,'',syntax_info,be_info);
}
_command void tex_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   select_edit_mode('tex');
}
/**
 * <p>Search for the next tag in Unix or Intel assembly code.</p>
 * 
 * <p>If <i>proc_name</i> is '', then this function searches for the first or next occurrence
 * of an identifier defined by PROC, MACRO, : (label), EQU, DB, DW, DD, or STRUC in the
 * current buffer.  Search always starts from cursor position.  The find_first parameter
 * indicates whether this is the first or next call.  <i>proc_name</i> is set to the identifier
 * with the identifier type concatenated in parentheses.  For example, for a PROC or label
 * with name xxx, <i>proc_name</i> would be set to "xxx(proc)" or "xxx(label)" respectively.</p>
 * 
 * <p>If <i>proc_name</i> is not '', then <i>proc_name</i> specifies the identifier name and type to be
 * found and is the format "name(type)".  Searching begins at the cursor position.
 * <i>find_first</i> must be non-zero if <i>proc_name</i> is not ''.  The cursor is placed on the
 * definition found, if one is found.</p>
 * 
 * @param proc_name  (reference) set to tag name, in the format:
 *                   <code>TAGNAME([CLASS:]TYPE)</code>
 *                   See tag_tree_compose_tag() for more details.
 * @param find_first find first match or next match?
 * 
 * @return 0 on success, non-zero on error, STRING_NOT_FOUND_RC
 *         if there are no more tags found.
 * @categories Search_Functions
 */
_str tex_proc_search(_str &proc_name, int find_first)
{
   _str search_key='';
   _str search_type='E';
   boolean do_search = false;
   boolean find_one = false;
   boolean proc_was_null;
   if (find_first)
   {
      if ( proc_name:=='' )
      {
         proc_was_null=true;
         search_key = '\\(chapter|section|subsection|subsubsection|label)\{(.*)\}';
         search_type = 'U';
         do_search = true;
      }
      else
      {
         parse proc_name with proc_name '('dmm_search_type')';
         proc_was_null=false;
         if (proc_name:=='')
         {
            search_key = '\\(chapter|section|subsection|subsubsection|label)\{(.*)\}';
            search_type = 'U';
            do_search = true;
         }
         else if (dmm_search_type:=='gvar')
         {
            search_key = '\label{'proc_name'}';
            search_type = 'E';
            do_search = true;
            find_one = true;
         }
         else if (dmm_search_type:=='proc')
         {
            search_key = '\'proc_name;
            search_type = 'E';
            do_search = true;
            find_one = true;
         }
      }
      if ( do_search)
      {
         search(search_key,search_type);
      }
   }
   else
   {
      repeat_search();
   }
   for (;;)
   {
      _str command = '';
      if (find_one)
      {
         if (!_in_comment())
         {
            return(rc);
         }
      }
      else
      {
         _str command = get_match_text('1');
         if ( command != '' && !_in_comment())
         {
            _str name = get_match_text('2');
            //message("command is " command " and name is " name);
            switch (command)
            {
            case 'chapter':
               if (find_first)
               {
                  proc_name='chapter{'name'}(proc)';
               }
               else if ( dmm_search_type:=='proc'|| proc_name:=='')
               {
                  proc_name='chapter{'name'}(proc)';
               }
               return(rc);
               break;
            case 'section':
               if (find_first)
               {
                  proc_name='section{'name'}(proc)';
               }
               else if ( dmm_search_type:=='proc'|| proc_name:=='')
               {
                  proc_name='section{'name'}(proc)';
               }
               return(rc);
               break;
            case 'subsection':
               if (find_first)
               {
                  proc_name='subsection{'name'}(proc)';
               }
               else if (dmm_search_type:=='proc' || proc_name:=='')
               {
                  proc_name='subsection{'name'}(proc)';
               }
               return(rc);
               break;
            case 'subsubsection':
               if (find_first )
               {
                  proc_name='subsubsection{'name'}(proc)';
               }
               else if (dmm_search_type:=='proc' || proc_name:=='')
               {
                  proc_name='subsubsection{'name'}(proc)';
               }
               return(rc);
               break;
            case 'label':
               if (find_first )
               {
                  proc_name = name'(gvar)';
               }
               else if (dmm_search_type:=='gvar' || proc_name:=='')
               {
                  proc_name = name'(gvar)';
               }
               return(rc);
               break;
            }
         }
      }
      repeat_search();
      if (rc)
      {
         break;
      }
   }
   return(rc);
}

