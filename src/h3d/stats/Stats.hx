/**
 * stats.hx
 * http://github.com/mrdoob/stats.as
 *
 * Released under MIT license:
 * http://www.opensource.org/licenses/mit-license.php
 *
 * How to use:
 *
 *	addChild( new Stats(engine) );
 *
 **/

package h3d.stats;


import flash.system.Capabilities;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.system.System;
import flash.text.StyleSheet;
import flash.text.TextField;
import flash.xml.XML;
import h3d.Engine;


class Stats extends Sprite {

    static inline var GRAPH_WIDTH : Int = 70;
    static inline var XPOS : Int = 69;//width - 1
    static inline var GRAPH_HEIGHT : Int = 50;
    static inline var TEXT_HEIGHT : Int = 90;

    private var xml : XML;

    private var text : TextField;
    private var style : StyleSheet;

    private var timer : Int;
    private var fps : Int;
    private var ms : Int;
    private var ms_prev : Int;
    private var mem : Float;
    private var mem_max : Float;

    private var graph : BitmapData;
    private var rectangle : Rectangle;

    private var fps_graph : Int;
    private var mem_graph : Int;
    private var ms_graph : Int;
    private var mem_max_graph : Int;
    private var _stage:Stage;

    var alignRight:Bool;
    var e:Engine;

    /**
     * <b>Stats</b> FPS, MS and MEM, all in one.
     */
    public function new(engine:Engine, alignRight:Bool = true) {

        super();
        mem_max = 0;
        fps = 0;

        e = engine;
        this.alignRight = alignRight;

        xml = new XML("<xml><fps>FPS:</fps><ms>MS:</ms><mem>MEM:</mem><memMax>MAX:</memMax><tris>TRIS:</tris><draws>DRW:</draws></xml>");
		
        style = new StyleSheet();
        style.setStyle('xml', {fontSize:'9px', fontFamily:'_sans', leading:'-2px'});
        style.setStyle('fps', {color: Colors.fpsCSS });
        style.setStyle('ms', {color: Colors.msCSS });
        style.setStyle('mem', {color: Colors.memCSS });
        style.setStyle('memMax', {color: Colors.memmaxCSS });

        style.setStyle('tris', {color: Colors.trisCSS });
        style.setStyle('draws', {color: Colors.drawsCSS });
        style.setStyle('tex', {color: Colors.texCSS });

        text = new TextField();
        text.width = GRAPH_WIDTH;
        text.height = TEXT_HEIGHT;
        text.styleSheet = style;
        text.condenseWhite = true;
        text.multiline = true;
        text.wordWrap = true;
        text.selectable = false;
        text.mouseEnabled = false;

        rectangle = new Rectangle(GRAPH_WIDTH - 1, 0, 1, GRAPH_HEIGHT);

        this.addEventListener(Event.ADDED_TO_STAGE, init, false, 0, true);
        this.addEventListener(Event.REMOVED_FROM_STAGE, destroy, false, 0, true);

    }

    private function init(e : Event) {

        _stage = stage;
        graphics.beginFill(Colors.bg);
        graphics.drawRect(0, 0, GRAPH_WIDTH, TEXT_HEIGHT);
        graphics.endFill();

        this.addChild(text);

        graph = new BitmapData(GRAPH_WIDTH, GRAPH_HEIGHT, false, Colors.bg);
        graphics.beginBitmapFill(graph, new Matrix(1, 0, 0, 1, 0, TEXT_HEIGHT));
        graphics.drawRect(0, TEXT_HEIGHT, GRAPH_WIDTH, GRAPH_HEIGHT);

        this.addEventListener(Event.ENTER_FRAME, update);

        if (alignRight) {
            _stage.addEventListener(Event.RESIZE, onStageResize);
            onStageResize(null);
        }

		addEventListener(MouseEvent.ROLL_OVER, onRollOver);
		addEventListener(MouseEvent.ROLL_OUT, onRollOut);
    }

	@:access(h3d.Engine)
    function onRollOver(_) {
        removeEventListener(Event.ENTER_FRAME, update);

        graph.fillRect(graph.rect, Colors.bg);
		
		if (e.ctx != null && e.ctx.driverInfo != "Disposed") {
			var s = e.mem.stats();
			var k = 100 / (1024 * 1024);
			var str = 'BUF:${s.bufferCount} TEX:${s.textureCount} MEM:${Std.int(s.totalMemory*k)/100} TEXmem:${Std.int(s.textureMemory*k)/100} FREE:${Std.int(s.freeMemory*k)/100}';

			text.htmlText = "<xml><tex>HW: " + e.hardware + "</tex>"+
				"<draws>" + Capabilities.version + (Capabilities.isDebugger ? " (debug)" : "") +
				"</draws><memMax>" + e.ctx.driverInfo + "</memMax>" +
				"<mem>" + str + "</mem></xml>";
		}
		else {
			text.htmlText = "<xml><tex>Disposed</tex>"+
				"<draws>" + Capabilities.version + (Capabilities.isDebugger ? " (debug)" : "") + "</xml>";
		}
        text.height = height;
    }

    function onRollOut(_) {
        text.height = 90;
        addEventListener(Event.ENTER_FRAME, update);
    }

    function onStageResize(_) {
        x = _stage.stageWidth - width;
    }

    private function destroy(e : Event) {

        graphics.clear();

        while(numChildren > 0)
            removeChildAt(0);

        graph.dispose();

        removeEventListener(Event.ENTER_FRAME, update);
        _stage.removeEventListener(Event.RESIZE, onStageResize);
    }

	@:access(h3d.Engine)
    private function update(_) {

        timer = flash.Lib.getTimer();

        //after a second has passed
        if( timer - 1000 > ms_prev ) {

            mem = System.totalMemory * 0.000000954;
            mem_max = mem_max > mem ? mem_max : mem;

            fps_graph = GRAPH_HEIGHT - Std.int( Math.min(GRAPH_HEIGHT, ( fps / _stage.frameRate ) * GRAPH_HEIGHT) );

            mem_graph = GRAPH_HEIGHT - normalizeMem(mem);
            mem_max_graph = GRAPH_HEIGHT - normalizeMem(mem_max);
            //milliseconds since last frame -- this fluctuates quite a bit
            ms_graph = Std.int( GRAPH_HEIGHT - ( ( timer - ms ) >> 1 ));
            graph.scroll(-1, 0);

            graph.fillRect(rectangle, Colors.bg);
            graph.lock();
            graph.setPixel(XPOS, fps_graph, Colors.fps);
            graph.setPixel(XPOS, mem_graph, Colors.mem);
            graph.setPixel(XPOS, mem_max_graph, Colors.memmax);
            graph.setPixel(XPOS, ms_graph, Colors.ms);
            graph.unlock();

            untyped xml.fps = "FPS: " + fps + " / " + stage.frameRate;
            untyped xml.mem = "MEM: " + Math.round(mem);
            untyped xml.memMax = "MAX: " + Math.round(mem_max);

            //reset frame and time counters
            fps = 0;
            ms_prev = timer;

            return;
        }
        //increment number of frames which have occurred in current second
        fps++;

		if (e.ctx != null && e.ctx.driverInfo != "Disposed") {
			untyped xml.tris = "TRIS: " + e.drawTriangles;
			untyped xml.draws = "DRW: " + e.drawCalls;
		}
		else {
			untyped xml.tris = "TRIS: N/A";
			untyped xml.draws = "DRW: N/A";
		}
		untyped xml.ms = "MS: " + (timer - ms);
        ms = timer;

        text.htmlText = xml.toString();
    }

    function normalizeMem(_mem:Float):Int {
        return Std.int( Math.min( GRAPH_HEIGHT, Math.sqrt(Math.sqrt(_mem * 5000)) ) - 2);
    }

}

class Colors {

    public static inline var bg : Int = 0x202020;
    public static inline var fps : Int = 0xffff00;
    public static inline var ms : Int = 0x00ff00;
    public static inline var mem : Int = 0x00ffff;
    public static inline var memmax : Int = 0xff0070;

    public static inline var bgCSS : String = "#000033";
    public static inline var fpsCSS : String = "#ffff00";
    public static inline var msCSS : String = "#00ff00";
    public static inline var memCSS : String = "#00ffff";
    public static inline var memmaxCSS : String = "#ff0070";

    public static inline var texCSS : String = "#FFFF00";
    public static inline var trisCSS : String = "#00FFFF";
    public static inline var drawsCSS : String = "#00FF00";

}