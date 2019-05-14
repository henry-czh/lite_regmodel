#!/usr/bin/env python
# -*- coding: UTF-8 -*- 

'''
    author: chaozhanghu
    email:  chaozhanghu@foxmail.com
    date:   2019.02.15
    version:1.0
    function: deal with strobe and data fields for partial access
'''
import sys
import xlrd

def gen_reg(output_file,reg_info):

    for data in reg_info:
        output_file.write('class %s extends lite_reg;\n' % (data["regname"]))
        output_file.write('\n')
        output_file.write('\tfunction new(string name="%s");\n' % (data["regname"]))
        output_file.write('\t\tsuper.new(name,32);\n')
        output_file.write('\tendfunction\n')
        output_file.write('\n')
        for value in data["fields"]:
            output_file.write('\trand lite_field\t\t%s;\n' % (value["fields"]))
        output_file.write('\n')
        output_file.write('\tfunction void build();\n')
        for value in data["fields"]:
            output_file.write('\t\t%s=new("%s");\n' % (value["fields"],value["fields"]))
            lsd=value["bits"].split(":")
            if len(lsd)==1:
                lsd=lsd[0]
                size=1
            else:
                size=str(int(lsd[0])-int(lsd[1])+1)
                lsd=lsd[1]
            output_file.write('\t\t%s.configure(%s,%s,"%s",0,\'h%s,1,0,0);\n' % 
            (value["fields"],size,lsd,value["access"],value["reset"].split("x")[1]))
            output_file.write('\t\tadd_field(%s);\n' % (value["fields"]))
        output_file.write('\tendfunction\n')
        output_file.write('\n')
        output_file.write('endclass\n')
        output_file.write('\n')
    
def deal_xls(sheet):
    book=xlrd.open_workbook(sys.argv[1])
    page=book.sheet_by_index(sheet)
    
    module_info = page.col_values(1)[0:6]

    i=7
    reg_info=[]
    for item in page.col_values(5)[7:]:
        if page.col_values(0)[i]!='':
            if i!=7:
                reg_item["fields"]=field_info
                reg_info.append(reg_item)
            field_info=[]
            reg_item={}
            reg_item["regname"]=page.col_values(0)[i]
            reg_item["offset"]=page.col_values(1)[i]

        field_item={}
        field_item["fields"]=page.col_values(2)[i]
        field_item["bits"]=page.col_values(3)[i]
        field_item["reset"]=page.col_values(4)[i]
        field_item["access"]=page.col_values(5)[i]
        field_item["hdl_path"]=page.col_values(7)[i]

        field_info.append(field_item)

        i=i+1

        if i==len(page.col_values(5)):
            reg_item["fields"]=field_info
            reg_info.append(reg_item)

        if item=='':
            break;

    return reg_info,module_info

def gen_regmodel(output_file,module_info):
    s='''
class %s_regmodel extends lite_regmodel;

    //add adaptor
    %s_adaptor adaptor;

    //virtual interface
    virtual %s_if avif;

    function new(string name="%s_regmodel",virtual interface apb_if avif);
        adaptor=new("adaptor");
        this.avif=avif;
    endfunction

    '''
    s=s % (module_info[0],module_info[4],module_info[4],module_info[0])
    output_file.write(s)

    for item in reg_info:
        output_file.write('\trand %s\t%s;\n' % (item["regname"],item["regname"]))
    output_file.write('\n')
        
    output_file.write('\tfunction void build();\n')
    output_file.write('\t\tadaptor.avif=avif;\n')
    output_file.write('\n')
    for item in reg_info:
        output_file.write('\t\t%s=new("%s");\n' % (item["regname"],item["regname"]))
        output_file.write('\t\t%s.build();\n' % (item["regname"]))
        output_file.write('\t\t%s.configure("%s",\'h%s);\n' % (item["regname"],module_info[5],item["offset"].split("x")[1]))
        output_file.write('\t\t%s.adaptor.push_back(adaptor);\n' % (item["regname"]))
        output_file.write('\t\tadd_reg(%s);\n' % (item["regname"]))
        output_file.write('\n')
    output_file.write('\tendfunction\n')
    output_file.write('\n')
    output_file.write('endclass\n')
        

if __name__=='__main__':
    (reg_info,module_info)=deal_xls(0)
    output_file=open('%s_regmodel.sv' % module_info[1],'w')
    gen_reg(output_file,reg_info)
    gen_regmodel(output_file,module_info)
    print "The file \"%s_regmodel.sv\" generat Successfully!" % (module_info[1])
    output_file.close()
