<div id="navlinks">

  <ul>
  <%- FOREACH item = links %>
    <%- IF item.current_page %>
      <li><% item.title %></li>
    <%- ELSE %>
      <li><a href="<% item.href %>"><% item.title %></a></li>
    <%- END -%>
  <%- END %>
  </ul>

  <div id="logos">
    <dl>
      <dt>Powered by:</dt>
      <dd><a href="http://gtk2-perl.sourceforge.net/"><img
        src="images/gtk-logo-rgb.gif" alt="gtk2-perl" /></a></dd>
      <dd><a href="http://www.perl.com/"><img
        src="images/perl_id_bw_sm_bu.gif" alt="Perl" /></a></dd>

      <dt>Hosted by:</dt>
      <dd><a href="http://sourceforge.net"><img
        src="http://sflogo.sourceforge.net/sflogo.php?group_id=126289&amp;type=2" 
        width="125" height="37" alt="SourceForge.net" /></a></dd>
    </dl>
  </div>
</div>

