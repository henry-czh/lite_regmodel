
class lite_hdl_path_check_tc;
    lite_regmodel   rgm;
    string          m_name;

    function new(string name="lite_hdl_path_check_tc");
        this.m_name = name;
    endfunction

    task start_test();
        foreach(rgm.m_regs[i]) begin
            rgm.m_regs[i].hdl_check;
        end
    endtask

endclass
