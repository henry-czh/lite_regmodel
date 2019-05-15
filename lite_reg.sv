
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

    task access_check();
        lite_reg_data_t field_value,ftdr_value;

        foreach (m_fields[i]) begin
            if(m_fields[i].m_access=="RW") begin
                //write frontdoor
                field_value=(~m_fields[i].mirror_value)<< m_fields[i].m_lsd;
                adaptor[0].reg2bus(m_addr,field_value);
                for(int j=0;j<=i;j++) begin
                    m_fields[j].update_desire((field_value >> m_fields[j].m_lsd) & ({`LITE_REG_MAX_WIDTH{1'b1}} >> (32-m_fields[j].m_size)));
                end
                //read backdoor
                #1;
                m_fields[i].bkdr_rd(m_hdl_path); 

                //write backdoor
                field_value=~(m_fields[i].mirror_value);
                m_fields[i].bkdr_wr(m_hdl_path,field_value); 
                //read frontdoor
                adaptor[0].bus2reg(m_addr,ftdr_data);
                m_fields[i].update_mirror((ftdr_data >> m_fields[i].m_lsd) & ({`LITE_REG_MAX_WIDTH{1'b1}} >> (32-m_fields[i].m_size)));
            end
            if(m_fields[i].m_access=="RO") begin
                //write backdoor
                field_value=~(m_fields[i].mirror_value);
                m_fields[i].force_wr(m_hdl_path,field_value); 
                //read frontdoor and check value
                adaptor[0].bus2reg(m_addr,ftdr_data);
                m_fields[i].update_mirror((ftdr_data >> m_fields[i].m_lsd) & ({`LITE_REG_MAX_WIDTH{1'b1}} >> (32-m_fields[i].m_size)));
                //release
                m_fields[i].release_wr(m_hdl_path); 
            end
            if(m_fields[i].m_access=="WO") begin
                string full_path;

                foreach (m_fields[i]) begin
                    //write frontdoor
                    field_value=(~m_fields[i].mirror_value)<< m_fields[i].m_lsd;
                    adaptor[0].reg2bus(m_addr,field_value);
                    for(int j=0;j<=i;j++) begin
                        m_fields[j].update_desire((field_value >> m_fields[j].m_lsd) & ({`LITE_REG_MAX_WIDTH{1'b1}} >> (32-m_fields[j].m_size)));
                    end
                    //read backdoor
                    full_path={m_hdl_path,".",m_fields[i].m_fname};
                    adaptor[0].wread(full_path,field_value,0);
                end
            end
            //...
        end
        $display("LITE_INFO @ %0tns : \"%s\" access check is successfully!",$time,m_name);
    endtask

    task reset_check();
        foreach (m_fields[i])
            m_fields[i].reset_check(m_hdl_path);
    endtask

    task hdl_check();
        foreach (m_fields[i])
            m_fields[i].hdl_check(m_hdl_path);
    endtask

    task fwrite(input lite_reg_data_t value);
        lite_reg_data_t field_value,ftdr_value;

        foreach (m_fields[i]) begin
            //write backdoor
            field_value=value >> m_fields[i].m_lsd;
            m_fields[i].force_wr(m_hdl_path,field_value); 
            //read frontdoor and check value
            adaptor[0].bus2reg(m_addr,ftdr_data);
            m_fields[i].update_mirror((ftdr_data >> m_fields[i].m_lsd) & ({`LITE_REG_MAX_WIDTH{1'b1}} >> (32-m_fields[i].m_size)));
            //release
            m_fields[i].release_wr(m_hdl_path); 
        end

        $display("LITE_INFO @ %0tns : \"%s\" read access is successfully!",$time,m_name);
    endtask
        
    task wread(input lite_reg_data_t value);
        lite_reg_data_t field_value;
        string full_path;

        foreach (m_fields[i]) begin
            full_path={m_hdl_path,".",m_fields[i].m_fname};
            field_value=(value >> m_fields[i].m_lsd) & ({`LITE_REG_MAX_WIDTH{1'b1}} >> (32-m_fields[i].m_size));
            adaptor[0].wread(full_path,field_value,1);
        end

    endtask
        
    task read(input lite_reg_access_t access_method,output lite_reg_data_t value);
        string access_method_s;
        
        if(access_method==FRONTDOOR) begin   //frontdoor access
            access_method_s="FRONTDOOR";
            adaptor[0].bus2reg(m_addr,ftdr_data);
            foreach (m_fields[i]) begin
                m_fields[i].update_mirror((ftdr_data >> m_fields[i].m_lsd) & ({`LITE_REG_MAX_WIDTH{1'b1}} >> (32-m_fields[i].m_size)));
            end
        end
        else begin                //backdoor access
            #0.1;
            access_method_s="BACKDOOR";
            foreach (m_fields[i]) begin
                m_fields[i].bkdr_rd(m_hdl_path); 
            end
        end

        value=0;
        foreach (m_fields[i]) begin
           value = value + (m_fields[i].get_mirror << m_fields[i].m_lsd); 
            //$display("field %d is %h",i,m_fields[i].get_mirror);
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
            #0.1;
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

