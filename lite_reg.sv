
class lite_reg;
    
    protected lite_field    m_fields[$];
    local lite_reg_data_t   m_addr;
    local lite_reg_data_t   ftdr_data;
    local lite_reg_data_t   m_width=0;
    local string            m_hdl_path;
    local string            m_name;

    lite_adaptor    adaptor[$];

    function void configure(string hdl_path,logic [31:0] addr);
        this.m_hdl_path=hdl_path;
        this.m_addr = addr;
    endfunction

    task read(input lite_reg_access_t access_method,output lite_reg_data_t value);
        string access_method_s;
        
        if(access_method==FRONTDOOR) begin   //frontdoor access
            access_method_s="FRONTDOOR";
            adaptor[0].bus2reg(m_addr,ftdr_data);
            foreach (m_fields[i]) begin
                //$display("ftdr_data is %h",ftdr_data);
                m_fields[i].update_mirror((ftdr_data >> m_fields[i].m_lsd) & ({`LITE_REG_MAX_WIDTH{1'b1}} >> (32-m_fields[i].m_size)));
            end
        end
        else begin                //backdoor access
            access_method_s="BACKDOOR";
            foreach (m_fields[i]) begin
                m_fields[i].bkdr_rd(m_hdl_path); 
            end
        end

        value=0;
        foreach (m_fields[i]) begin
           value = value + (m_fields[i].get_mirror << m_fields[i].m_lsd); 
        end

        $display("LITE_INFO @%0tns [%s] : The register \"%s\"  read value is 'h%h",$time,access_method_s,m_name,value);

    endtask

    task write(input lite_reg_access_t access_method,input lite_reg_data_t value);
        lite_reg_data_t field_value;
        string access_method_s;

        if(access_method==FRONTDOOR) begin  //frontdoor access
            access_method_s="FRONTDOOR";
            adaptor[0].reg2bus(m_addr,value);
            foreach (m_fields[i]) begin
                m_fields[i].update_desire((value >> m_fields[i].m_lsd) & ({`LITE_REG_MAX_WIDTH{1'b1}} >> (32-m_fields[i].m_size)));
            end
        end
        else begin               //backdoor access
            access_method_s="BACKDOOR";
            foreach (m_fields[i]) begin
                field_value=value >> m_fields[i].m_lsd;
                m_fields[i].bkdr_wr(m_hdl_path,field_value); 
            end
        end
        $display("LITE_INFO @%0tns [%s] : The register \"%s\"  write value is 'h%h",$time,access_method_s,m_name,value);
    endtask
    
    function new(string name="lite_reg",logic [127:0] reg_width);
        m_width = reg_width;
        m_name=name;
    endfunction

    //add wait task for read RO register ,for example, wait for phy pll lock
    task read_untill(logic [31:0] user_value);
        wait(m_hdl_path==user_value);
    endtask

    //add fields to reg
    extern function void add_field(lite_field field);

endclass

function void lite_reg::add_field(lite_field field);
    int offset;
    int ids=-1;

    offset = field.m_lsd;
    foreach (m_fields[i]) begin
        if(offset < m_fields[i].m_lsd) begin
            int j =i ;
            m_fields.insert(j,field);
            ids = i;
            break;
        end
    end
    if(ids<0)
        m_fields.push_back(field);
endfunction

