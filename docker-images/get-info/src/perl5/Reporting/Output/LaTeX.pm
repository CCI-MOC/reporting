
package Reporting::Output::LaTeX;

use strict;

sub vm_subsection
{
    my ($vm, $flav, $t1, $t2) = @_;

    my $total_hours = 0;
    my $total_amt   = 0.00;
    my $amp         = 0.0;
    my $rpt         = "\\begin{table}[htbp]\n"
                    . "\\begin{tabular}{l l r r }\n"
                    . "VM Name & VM ID & Hours & Amt \\\\\n";

    foreach my $vm_id (sort keys %{$vm})
    {
        my $hours;
        my $amt;
        if($vm->{$vm_id}->{event_cnt}>0)
        {
            ($hours, $amt) = tally_hours2($vm->{$vm_id}->{events}, $flav);
        }
        else
        {
            $hours=0; $amt=0.0;
        }
        $total_hours+=$hours;
        #$total_amp=$total_amt+$amt;
        $rpt=$rpt."$vm->{$vm_id}->{name} & $vm_id & $hours & $amt\\\\\n";
    }
    $rpt = $rpt."VM Totals & & $total_hours &";
    $rpt = $rpt."\\end{tabular}\n"
             ."\\end{table}\n";
    return ($rpt, $total_amt);
}

# Yes this combines both the project report and tallying up for the project report
# To split this would require similar work to be done in each
sub gen_project_reports
    {
    my ($os_info, $flav, $proj_rpt_filename, $t1, $t2) = shift;
    my $rpt;  # this is just a string containing the latex for the report.
    my $sub_total;
    my $total=0;

    $rpt = "\\documentclass[10pt]{article}\n"
         . "\\usepackage [margin=0.5in] {geometry}\n"
         . "\\pagestyle{empty}\n"
         . "\\usepackage{tabularx}\n"
         . "\%\\usepackage{doublespace}\n"
         . "\%\\setstretch{1.2}\n"
         . "\\usepackage{ae}\n"
         . "\\usepackage[T1]{fontenc}\n"
         . "\\usepackage{CV}\n"
         . "\\begin{document}\n";

    my $proj=$os_info->{project};
    foreach my $proj_id (sort keys %{$proj})
    {
        $rpt .= "\\begin{flushleft} \\textbf{\\textsc{OCX Project Report}}\\end{flushleft}\n"
              . "\\begin{flushleft} \\textsc{  Project: $proj->{$proj_id}->{name} id: $proj_id }\\end{flushleft}\n"
              . "\\flushleft{ \\textsc{     From: ".$t1."}}\n"
              . "\\flushleft{ \\textsc{     To: ".$t2."}}\n"
              . "\\newline\n";
        if($proj->{$proj_id}->{vm_cnt}>0)
        {
            my $sub_rpt;
            ($sub_rpt, $sub_total) = vm_subsection($proj->{$proj_id}->{VM},$flav,$t1,$t2);
            
            $rpt .= $sub_rpt;
        }
        else
        {
            $sub_total=0;
        }
        $total+=$sub_total;
        # vol_reports($proj->{$proj_id}->{Vol});
        # present a grand total
        $rpt=$rpt."";
        $rpt=$rpt."\\pagebreak\n";
    }

    $rpt=$rpt."\\end{document}";

    if(open($FP,">", $proj_rpt_filename))
    {
        print $FP $rpt;
    }
    else
    {
        print STDERR "\n\n".$rpt."\n\n";
    }
}
