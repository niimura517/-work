module ADCMCKSEL(
input _24M, _22M,
input ADC22M,
output MCK
);


assign MCK = ADC22M? _22M : _24M;

endmodule

