`define LITE_REG_MAX_WIDTH 32
typedef logic [`LITE_REG_MAX_WIDTH -1:0] lite_reg_data_t;
typedef enum {FRONTDOOR,BACKDOOR} lite_reg_access_t;
typedef enum {ACC,FUNC} lite_reg_mode_t;


