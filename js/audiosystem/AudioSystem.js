/*jslint browser: true */
/*global AudioContext */

'use strict';

(function (w) {

    var LCLSoundSystem, soundprocess, sound, scriptNode, context, config;

    config = {
        buffersize: 2048
    };

    sound = function (e) {

        var i, data;
        data = e.outputBuffer.getChannelData(0);

        for (i = 0; i < data.length; i += 1) {
            data[i] = ((i % 100) / 100);
        }

    };

    context = new AudioContext();
    scriptNode = context.createJavaScriptNode(config.buffersize, 0, 1);

    scriptNode.connect(context.destination);
    scriptNode.onaudioprocess = function (e) {
        console.log('audioproc');
        sound(e);
    };


    w.LCLSoundSystem = LCLSoundSystem = function () {
        w.oscillator = this.oscillator;
        w.gain = this.gain;
        w.filter = this.filter;
        w.out = this.out;
    };

    // arguments
    // node:    The node that will have it's output sent to the DAC
    //
    // returns
    // null
    LCLSoundSystem.prototype.out = function (node) {

        console.log('outout');
        sound = function (e) {

            console.log('callback');

            var i, data, output;
            data = e.outputBuffer.getChannelData(0);

            output = node(data.length);

            for (i = 0; i < data.length; i += 1) {
                data[i] = output[i];
            }

        };

    };

    // arguments
    // freq:    The frequency of the oscillator
    // returns
    // The audio generation function
    LCLSoundSystem.prototype.oscillator = function (freq) {
        var output;

        return function (samplenum) {
            var i, audio;

            audio = [];

            for (i = 0; i < samplenum; i += 1) {
                audio[i] = (i / samplenum);
            }

            return audio;
        };
    };

    // arguments
    // input:   The audio node to filter
    // returns
    // The audio generation function
    LCLSoundSystem.prototype.filter = function (input) {
        var output, lastsample;
        lastsample = 0;

        return function (samplenum) {
            var i, inputdata, audio;
            inputdata = input(samplenum);
            audio = [];
            for (i = 0; i < samplenum; i += 1) {
                audio[i] = (inputdata[i] + lastsample) / 2;
                lastsample = inputdata[i];
            }
            return audio;
        };
    };

    // arguments
    // gain:    The value to multiply the audio by
    // input:   The input audio node
    // returns
    // The audio generation function
    LCLSoundSystem.prototype.gain = function (gain, node) {
        var output;

        return function (samplenum) {
            var i, inputdata, audio;
            inputdata = node(samplenum);
            audio = [];
            for (i = 0; i < samplenum; i += 1) {
                audio[i] = inputdata[i] * gain;
            }
            return audio;
        };
    };

}(window));

