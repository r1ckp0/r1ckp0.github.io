(~lfsr = { |bits = 7, seed = 1, taps = #[0, 1]|
	var registro, xor, numero;
	numero = seed;
	registro = ((2**bits)-1).asInteger.collect{
		xor = ((numero >> taps[0]) & 1) bitXor: ((numero >> taps[1]) & 1);
		numero = (numero >> 1) | (xor << (bits - 1));
		numero.asInteger
	};
	registro = registro.as(OrderedIdentitySet).as(Array) & 1;
	(registro - 1) * -1
});


///////////

((~lfsr = { |bits = 4, seed = 1, taps = #[0, 1]|
	var registro, xor, numero, divisor;
	numero = seed;
	registro = ((2**bits)-1).asInteger.collect{
		xor = ((numero >> taps[0]) & 1) bitXor: ((numero >> taps[1]) & 1);
		numero = (numero >> 1) | (xor << (bits - 1));
		numero.asInteger
	};
	registro = registro.as(OrderedIdentitySet).as(Array) & 1;
});
(~audc0011={
	|bits = 4, seed = 1, taps = #[0, 1]|
	var fivebit, registro, xor, numero, divisor;
	fivebit = (~lfsr.(5, 7, [0, 2])!15 ).flatten;
	numero = seed;
	registro = (fivebit.size).asInteger.collect{|i|
		if(fivebit[i] == 1,
			{xor = ((numero >> taps[0]) & 1) bitXor: ((numero >> taps[1]) & 1);
				numero = (numero >> 1) | (xor << (bits - 1));
				numero.asInteger},
			{numero})
	};
	registro & 1;
})
)


///////////


(~lfsr = {|bits = 23, seed = 1, taps = #[0, 4]|
	var registro, xor, numero, salida;
	numero = seed;
	salida = [];
	registro = ((2**bits) - 1).asInteger.collect{
		xor = ((numero >> taps[0]) & 1).bitXor((numero >> taps[1]) & 1);

		numero = (numero >> 1) | (xor << (bits - 1));
		salida = salida.add([
			((numero >> 20) & 1) * 2**7,
			((numero >> 18) & 1) * 2**6,
			((numero >> 14) & 1) * 2**5,
			((numero >> 11) & 1) * 2**4,
			((numero >> 9) & 1) * 2**3,
			((numero >> 5) & 1) * 2**2,
			((numero >> 2) & 1) * 2**1,
			((numero >> 0) & 1) * 2**0].sum);

		numero.asInteger
	};
	registro = registro.as(OrderedIdentitySet).as(Array);
	salida.takeThese{|item, index| index >= registro.size} / 255
})


///////////


b = Buffer.sendCollection(s, ~lfsr.(23), 1);
(
SynthDef(\lfsr, { |bufnum, amp = 0.1, freq|
	var phase, sig;
	phase = Phasor.ar(0, freq * SampleDur.ir, 0, BufFrames.kr(bufnum));
	sig = BufRd.ar(1, bufnum, phase, interpolation: 1);
	Out.ar(0, sig*amp !2)
}
).add)
Synth(\lfsr, [ \bufnum, b, \amp, 0.3, \freq, 440 ])


//////////////

(
(~snap2freq = { |freq|
	var possibleFreqs, actualFreq;
	possibleFreqs = [
		440, 879.9, 1761.6, 2348.8, 3523.2, 4709.9, 7046.3, 8860.3,
		11186.1, 13982.6, 18643.5, 27965.2, 55930.4, 111860.8, 223721.6, 447443.2
	];
	actualFreq = possibleFreqs[possibleFreqs.indexIn(freq)]
});
(
SynthDef(\lfsr, {
	|bufnum, amp = 0.1, attack = 0, decay = 0.2, sustain = 0.7,release = 0.2, gate = 1, freq = 440, pan = 0|
	var phase, sig, possibleFreqs, actualFreqs, env, freqs;
	freqs = Latch.kr(freq, Impulse.kr(60));
	env = Latch.ar(
		EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, doneAction:2) * 15,
		Impulse.ar(60)
	).round(1) / 15;
	phase = Phasor.ar(0, freqs * SampleDur.ir, 0, BufFrames.kr(bufnum));
	sig = BufRd.ar(1, bufnum, phase, interpolation: 1);
	sig = Pan2.ar(sig * env, pan);
	Out.ar(0, sig*amp)
}
).add)
)
a = Synth(\lfsr, [ \bufnum, b, \amp, 1, \freq, ~snap2freq.(700), \attack, 1, \release, 2 ])


///////////////




(SynthDef(\GBpulse, {
	|cycles = #[1, 0, 1, 0], lag = 0, curve = 2, repeats = inf, amp = 1,
	attack = 0.1, decay = 0.2, sustain = 0.8, release = 1, gate = 1, pan = 0 |
	var dutyCycles, sig, frecuencia, env, actualCycle;
	frecuencia = Latch.kr(VarLag.kr(\freq.kr(440), lag, curve), Impulse.kr(60));
	dutyCycles = [[0,0,0,0,0,0,0,1], [1,0,0,0,0,0,0,1], [1,0,0,0,0,1,1,1], [0,1,1,1,1,1,1,0]];
	actualCycle = Select.kr(Demand.ar(Impulse.ar(60), 0, Dseq(cycles, repeats)), dutyCycles);
	env = Latch.ar(
		EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, doneAction:2) * 15,
		Impulse.ar(60)
	).round(1) / 15;
	sig = Duty.ar(1/frecuencia/8, 0, Dseq(actualCycle, inf));
	sig = Pan2.ar(sig * env, pan);
	Out.ar(0, sig * amp)
}).add
)
x = Synth(\GBpulse, [\cycles, [2,2,2,2], \repeats, inf,\amp, 0.3])

////////

(
(~vrc6saw={ |a|
	var array;
	array = Array.fill(7, {|i| i * a}).dupEach.asInteger;
	array = [(array>>3 & 1), (array>>4 & 1)*2, (array>>5 & 1)*4, (array>>6 & 1)*8, (array>>7 & 1)*16].sum / 31
});
SynthDef(\vrc6saw,{
	|pan = 0, amp = 1, sawAmp = 42, lag = 0, curve = 2,
	attack = 0.1, decay = 0.2, sustain = 0.8, release = 1, gate = 1|
	var sig, env, frecuencia;
	frecuencia = Latch.kr(VarLag.kr(\freq.kr(440), lag, curve), Impulse.kr(60));
	sig = DemandEnvGen.ar(Dseq(~vrc6saw.(sawAmp), inf), 1/frecuencia/14, shape: 0, curve: 0);
	env = Latch.ar(
		EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, doneAction:2) * 15,
		Impulse.ar(60)
	).round(1) / 15;
	sig = Pan2.ar(sig * env, pan);
	Out.ar(0, sig * amp);
}).add
)
t = Synth(\vrc6saw)

///////

~waveform = ([15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]/15);//triangular NES
(SynthDef(\GBWaveform, {
	|lag = 0, curve = 2, attack = 0.1, decay = 0.2, sustain = 0.8, release = 1, gate = 1, pan = 0, amp = 1|
	var sig, frecuencia, env;
	frecuencia = Latch.kr(VarLag.kr(\freq.kr(440), lag, curve), Impulse.kr(60));
	sig = DemandEnvGen.ar(Dseq(\array.kr(0!32), inf), 1/frecuencia/32, 0, 0);
	env = Latch.ar(EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, doneAction:2) * 15,
		Impulse.ar(60)
	).round(1) / 15;
	sig = Pan2.ar(sig * env, pan);
	Out.ar(0, sig)
}).add)
y = Synth(\GBWaveform, [\array, ~waveform])


////////

(
SynthDef(\namco163, {
	|freq = 440, size = 256, lag = 0, curve = 2,
	attack = 0.1, decay = 0.2, sustain = 0.8, release = 1, gate = 1, pan = 0, amp = 1|
	var sig, array, frecuencia, env;
	frecuencia = Latch.kr(VarLag.kr(freq, lag, curve), Impulse.kr(60));
	array = \array.kr(0!256);

	sig = DemandEnvGen.ar(Dswitch1(array, Dseries(0, 1, inf) % size), Dseq(1/frecuencia/size, inf), 0, 0);
	env = Latch.ar(
		EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, doneAction:2) * 15,
		Impulse.ar(60)
	).round(1) / 15;
	sig = Pan2.ar(sig * env, pan);
	Out.ar(0, sig)
}).add
)
z = Synth(\namco163, [\array, ~waveform, \freq, 600])
z.set(\size, 15)


////


({Latch.ar(SinOsc.ar, Impulse.ar(16000)).round(1/2**4)}.play)


/////

(
//sine

~sine0 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

~sine1 = [0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0];

~sine2 = [0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0];

~sine3 = [0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0];

~sine4 = [0, 0, 0, 0, 0, 1, 1, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 2, 1, 1, 0, 0, 0, 0, 0, 0];

~sine5 = [0, 0, 0, 0, 0, 1, 1, 2, 3, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 3, 2, 1, 1, 0, 0, 0, 0, 0];

~sine6 = [0, 0, 0, 0, 1, 1, 2, 3, 4, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 4, 3, 2, 1, 1, 0, 0, 0, 0, 0];

~sine7 = [0, 0, 0, 0, 1, 1, 2, 3, 4, 5, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 6, 6, 5, 4, 3, 2, 1, 1, 0, 0, 0, 0];

~sine8 = [0, 0, 0, 0, 1, 1, 2, 3, 5, 6, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 7, 7, 6, 5, 3, 2, 1, 1, 0, 0, 0, 0];

~sine9 = [0, 0, 0, 1, 1, 2, 3, 4, 6, 7, 8, 8, 9, 9, 9, 9, 9, 9, 9, 8, 8, 7, 6, 5, 3, 2, 1, 1, 0, 0, 0, 0];

~sine10 = [0, 0, 0, 1, 1, 2, 3, 5, 7, 8, 9, 9, 10, 10, 10, 10, 10, 10, 10, 9, 9, 8, 7, 5, 3, 2, 1, 1, 0, 0, 0, 0];

~sine11 = [0, 0, 0, 1, 1, 2, 3, 5, 6, 8, 9, 10, 10, 11, 11, 11, 11, 11, 11, 10, 10, 9, 8, 6, 5, 3, 2, 1, 1, 0, 0, 0];

~sine12 = [0, 0, 1, 1, 2, 3, 4, 6, 8, 9, 10, 11, 11, 12, 12, 12, 12, 12, 11, 11, 10, 9, 8, 6, 4, 3, 2, 1, 1, 0, 0, 0];


//pulse

~pulse0 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

~pulse1 = [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

~pulse2 = [3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0];

~pulse3 = [3, 3, 3, 3, 0, 0, 0, 0, 3, 3, 3, 3, 0, 0, 0, 0, 3, 3, 3, 3, 0, 0, 0, 0, 3, 3, 3, 3, 0, 0, 0, 0];

~pulse4 = [3, 3, 0, 0, 3, 3, 0, 0, 3, 3, 0, 0, 3, 3, 0, 0, 3, 3, 0, 0, 3, 3, 0, 0, 3, 3, 0, 0, 3, 3, 0, 0];

~pulse5 = [3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0];

)

///////

(Routine{
	y = Synth(\GBWaveform);

	4.do{ |i|
		y.set(\array, (~sine12 + ~pulse1)/15, \note, [32, 34, 36, 30, 39].choose + i);
		0.5.wait;
		y.set(\array, (~sine10)/15);
		0.5.wait;
		y.set(\array, (~sine8 + (~pulse5*1/3))/15);
		0.5.wait;
		y.set(\array, (~sine6)/15);
		0.5.wait;
		y.set(\array, (~sine0)/15);
		0.5.wait;
		y.set(\array, (~sine3)/15);
		0.5.wait;
		y.set(\array, (~pulse2)/15);
		0.25.wait;
		y.set(\array, (~pulse3 * 2/3)/15);
		0.25.wait;
		y.set(\array, (~sine6)/15);
		0.5.wait;
		y.set(\array, (~sine12)/15);
		0.5.wait;
		y.set(\array, (~sine10)/15);
		0.5.wait;
		y.set(\array, (~sine8)/15);
		0.5.wait;
		y.set(\array, (~sine6)/15);
		0.5.wait;
		y.set(\array, (~pulse4 * 1/3)/15);
		0.5.wait;
		y.set(\array, (~sine3)/15);
		0.5.wait;
		y.set(\array, (~sine0)/15);
		0.5.wait;
		y.set(\array, (~sine6 + ~pulse1)/15);
		0.5.wait;
	};
	20.do{|j|
		y.set(\array, (~sine6 + [~pulse0, ~pulse1, ~pulse3, ~pulse5].choose)/15);
		(0.3/((j+1)/2)).wait;
		y.set(\array, (~sine0)/15);
		(0.7/((j+1)/2)).wait;
	}
}.play(TempoClock(18/6)))

////////

y = Synth(\GBWaveform, [\array, (~pulse4 * ~sine12)%16 /15]);

///////

(
(SynthDef(\rhydon1, { |cycles = #[3, 3, 0, 0], lag = 0, rate = 1, repeats = 16, amp = 1|
	var dutyCycles, signal, freq, env, actualCycle;

	freq = EnvGen.ar(
		Env([0, 1365.33, 1424, 1365.33, 585.14, 593.15, 606.81, 630],
			[8, 10, 6, 17, 10, 4, 10]/60,
			\step));

	dutyCycles = [[0,0,0,0,0,0,0,1], [1,0,0,0,0,0,0,1], [1,0,0,0,0,1,1,1], [0,1,1,1,1,1,1,0]];


	actualCycle = Select.kr(Demand.kr(Impulse.kr(60/rate), 0, Dseq(cycles, repeats)), dutyCycles);


	env = EnvGen.ar(Env(
		[0, 15, 14, 14, 13, 13, 13, 12, 11, 10, 9, 8, 12, 11, 10, 9, 12, 11, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]/15,
		[7, 1, 6, 4, 6, 3, 3, 3, 3, 3, 2, 3, 3, 3, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]/60,
		\step
	));

	signal = Duty.ar(1/freq/8, 0, Dseq(actualCycle, inf)) !2;


		Out.ar(0, signal*env*0.3)
}).add
);


(SynthDef(\rhydon2, { |cycles = #[0, 0, 2, 2], lag = 0, rate = 1, repeats = inf|
	var dutyCycles, signal, freq, env, actualCycle;

	freq = EnvGen.ar(
		Env([0, 64, 686.78, 693.60, 686.78, 412.42, 410.09, 425.45, 442.16],
			[6, 8, 10, 6, 15, 9, 5, 10]/60,
			\step));


	dutyCycles = [[0,0,0,0,0,0,0,1], [1,0,0,0,0,0,0,1], [1,0,0,0,0,1,1,1], [0,1,1,1,1,1,1,0]];


	actualCycle = Select.kr(Demand.kr(Impulse.kr(60/rate), 0, Dseq(cycles, repeats)), dutyCycles);


	env = EnvGen.ar(Env(
		[1, 0, 10, 9, 8, 7, 7, 8, 7, 6, 5, 4, 7, 6, 5, 8, 7, 6, 7, 6, 5, 4, 3, 2, 1, 0]/15,
		[6, 7, 1, 6, 4, 6, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1]/60,
		\step
	));

	signal = Duty.ar(1/freq/8, 0, Dseq(actualCycle, inf)) !2;


		Out.ar(0, signal * env * 0.3)
}).add
);

(~lfsr = { |bits = 7, seed = 1, taps = #[0, 1]|
    var registro, xor, numero;
    numero = seed;
    registro = ((2**bits)-1).asInteger.collect{
		xor = ((numero >> taps[0]) & 1) bitXor: ((numero >> taps[1]) & 1);
        numero = (numero >> 1) | (xor << (bits - 1));
        numero.asInteger
    };
    registro = registro.as(OrderedIdentitySet).as(Array) & 1;
	(registro - 1) * -1
});
b = Buffer.sendCollection(s, ~lfsr.value(7), 1);
(
SynthDef(\rhydon4, { |bufnum|
	var phase, sig, freq, env;
	freq = EnvGen.ar(
		Env([0, 4096, 16384, 16384, 16384, 8192, 6553.6, 16384],
			[4, 8, 6, 8, 10, 14, 10]/60,
			\step));

	env = EnvGen.ar(Env(
		[0, 15, 14, 14, 13, 13, 13, 12, 14, 13, 13, 12, 11, 10, 9, 8, 7, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]/15,
		[2, 2, 6, 2, 6, 6, 2, 5, 5, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]/60,
		\step
	));
	phase = Phasor.ar(0, freq * SampleDur.ir, 0, BufFrames.kr(bufnum));
	sig = BufRd.ar(1, bufnum, phase, interpolation: 1)!2;
	Out.ar(0, sig * env * 0.3)
}
).add
);

)

////////

(
Synth(\rhydon2);
Synth(\rhydon1);
Synth(\rhydon4, [\bufnum, b])
)
