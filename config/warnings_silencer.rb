require "warning"

# ignore gdal warnings
Warning.ignore(/undefining the allocator of T_DATA class/)
Warning.ignore(/undefining the allocator of T_DATA class SWIG::TYPE_p_f_double_p_q_const__char_p_void__int/)
