
class lite_reset_check_tc;
    lite_regmodel   rgm;
    string          m_name;

    function new(string name="lite_reset_check_tc");
        this.m_name = name;
    endfunction

    task start_test();
        foreach(rgm.m_regs[i]) begin
            rgm.m_regs[i].reset_check;
        end
    endtask

endclass
