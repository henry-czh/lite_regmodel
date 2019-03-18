
class lite_reg;
    
    protected lite_field    m_fields[$];
    local logic [31:0]      m_addr;
    local logic [31:0]      m_width=0;
    local string            m_hdl_path;

    function void configure(string hdl_path,logic [31:0] addr);
        this.m_hdl_path=hdl_path;
        this.m_addr = addr;
    endfunction

    function void read(input bit access_method,output lite_reg_data_t value);
        if(access_method)   //frontdoor access
            ;
        else                //backdoor access
            foreach (m_fields[i]) begin
               m_fields[i].bkdr_rd(m_hdl_path); 
            end

        value=0;
        foreach (m_fields[i]) begin
           $display("%d :field value is %h",i,m_fields[i].mirror_value);
           $display("%d :field lsd is %h",i,m_fields[i].m_lsd);
           value = value + (m_fields[i].mirror_value << m_fields[i].m_lsd); 
           $display("%d :comb value is %h",i,value);
        end

    endfunction

    function write();
    endfunction
    
    function new(string name="lite_reg",logic [127:0] reg_width);
        m_width = reg_width;
    endfunction

    //add wait task for read RO register ,for example, wait for phy pll lock
    task read_untill(logic [31:0] user_value);
        wait(m_hdl_path==user_value);
    endtask

    //add fields to reg
    extern function void add_field(lite_field field);

endclass

function void lite_reg::add_field(lite_field field);
    m_fields.push_back(field);
endfunction

