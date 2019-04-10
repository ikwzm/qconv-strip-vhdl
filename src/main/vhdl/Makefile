
ENTITY_FILES = qconv_strip_axi_core.vhd             \
               qconv_strip_core.vhd                 \
               qconv_strip_controller.vhd           \
               qconv_strip_registers.vhd            \
               qconv_strip_in_data_buffer.vhd       \
               qconv_strip_th_data_buffer.vhd       \
               qconv_strip_k_data_buffer.vhd        \
               qconv_multiplier.vhd                 \
               qconv_apply_thresholds.vhd           \
               qconv_strip_k_data_axi_reader.vhd    \
               qconv_strip_in_data_axi_reader.vhd   \
               qconv_strip_th_data_axi_reader.vhd   \
               qconv_strip_out_data_axi_writer.vhd  \
               ${ENDLIST}

qconv_components.vhd : ${ENTITY_FILES}
	../../../PipeWork/tools/MakeComponentPackage.rb --verbose \
            --brief   'Quantized Convolution Component Library' \
            --version 0.1.0 \
            --author  'Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>' \
            --library QCONV \
            --package QCONV_COMPONENTS \
            --output  qconv_components.vhd \
            ${ENTITY_FILES}

clean:
	-rm qconv_components.vhd
