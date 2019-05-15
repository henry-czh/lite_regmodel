
class lite_regmodel;
    function new(string name="");
    endfunction

    lite_reg  m_regs[$];

    extern function void add_reg(lite_reg register);
endclass

function void lite_regmodel::add_reg(lite_reg register);

    m_regs.push_back(register);
endfunction
