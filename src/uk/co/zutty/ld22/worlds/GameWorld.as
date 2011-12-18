package uk.co.zutty.ld22.worlds
{
    import flash.geom.Point;
    
    import net.flashpunk.Entity;
    import net.flashpunk.FP;
    import net.flashpunk.Sfx;
    import net.flashpunk.World;
    
    import uk.co.zutty.ld22.Main;
    import uk.co.zutty.ld22.entities.Baddie;
    import uk.co.zutty.ld22.entities.Bystander;
    import uk.co.zutty.ld22.entities.Cigarette;
    import uk.co.zutty.ld22.entities.Manuscript;
    import uk.co.zutty.ld22.entities.Player;
    import uk.co.zutty.ld22.entities.Speaker;
    import uk.co.zutty.ld22.hud.CigarettesIndicator;
    import uk.co.zutty.ld22.hud.DamageBar;
    import uk.co.zutty.ld22.hud.FullScreenMessage;
    import uk.co.zutty.ld22.levels.Layer;
    import uk.co.zutty.ld22.levels.Level;
    import uk.co.zutty.ld22.levels.Level1;
    import uk.co.zutty.ld22.levels.OgmoLevel;
    
    public class GameWorld extends World {
        
        public static const RESPAWN_TICKS:int = 80;
        
        [Embed(source = 'assets/crisis.mp3')]
        private const CRISIS_SOUND:Class;
        [Embed(source = 'assets/fall.mp3')]
        private const FALL_SOUND:Class;

        private var player:Player;
        private var failMsg:FullScreenMessage;
        private var fagsInd:CigarettesIndicator;
        private var damageBar:DamageBar;
        private var respawnTick:int;
        
        private var _level:Level;
        private var happySky:Layer;
        private var happyGround:Layer;
        private var sadSky:Layer;
        private var sadGround:Layer;
        
        private var _fallSfx:Sfx;
        private var _crisisSfx:Sfx;

        public function GameWorld() {
            super();
            
            _fallSfx = new Sfx(FALL_SOUND);
            _crisisSfx = new Sfx(CRISIS_SOUND);
            
            // Add the sky and ground
            _level = new Level1();
            happySky = _level.getLayer("sky");
            happyGround = _level.getLayer("ground", true);
            add(happySky);
            add(happyGround);

            sadSky = _level.getLayer("sad_sky");
            sadGround = _level.getLayer("sad_ground", true);
            sadSky.sad = true;
            sadGround.sad = true;
            add(sadSky);
            add(sadGround);
            
            // Add all powerups
            var p:Point;
            for each(p in _level.getObjectPositions("objects", "manuscript")) {
                add(new Manuscript(p.x + 8, p.y + 8));
            }
            for each(p in _level.getObjectPositions("objects", "cigarette")) {
                add(new Cigarette(p.x + 8, p.y + 8));
            }
            
            // Add the player
            player = new Player();
            player.onTrapped = dieTrapped;
            add(player);
            
            // Draw bystanders
            var bystander:Bystander = new Bystander(200, 80);
            bystander.target = player;
            add(bystander);
            
            // Add all banalities
            for each(var b:Entity in Main.banalities.entities) {
                add(b);
            }
            for each(var bl:Entity in Main.bleaknesses.entities) {
                add(bl);
            }

            // Draw baddies   
            for each(p in _level.getObjectPositions("baddies", "turmoil")) {
                add(new Baddie(p.x + 12, p.y + 12));
            }

            // Draw the HUD over everything
            damageBar = new DamageBar(20, 220);
            add(damageBar);
            fagsInd = new CigarettesIndicator(280, 220);
            add(fagsInd);
            failMsg = new FullScreenMessage();
            add(failMsg);

            // Start
            balanceLayers();
            spawn();
            fagsInd.setCharges(player.healCharges, Player.HEAL_MAX_CHARGES);
        }
        
        public function get level():Level {
            return _level;
        }
        
        public function spawn():void {
            player.spawn();
            player.x = 160;
            player.y = 120;
            respawnTick = 0;
            failMsg.hide();
        }
        
        public function dieTrapped():void {
            _crisisSfx.play();
            die("You fell victim\nto absurdity");
        }
        
        public function die(msg:String):void {
            player.die();
            respawnTick = RESPAWN_TICKS;
            failMsg.show(msg);
        }
        
        public function win():void {
            failMsg.show("You done won");
            player.active = false;
        }
        
        public function balanceLayers():void {
            var balance:Number = player.damagePct;
            happySky.tilemap.alpha = 1 - tween(balance, 0.3, 0.7);
            happyGround.tilemap.alpha = 1 - tween(balance, 0.3, 0.7);
            
            sadSky.tilemap.alpha = tween(balance, 0.3, 0.7);
            sadGround.tilemap.alpha = tween(balance, 0.3, 0.7);
            
            // Set collidableness
            happyGround.collidable = player.damagePct < 0.65; 
            sadGround.collidable = player.damagePct > 0.35; 
        }
        
        public function get sadAlpha():Number {
            return tween(player.damagePct, 0.3, 0.7);
        }
        
        private function tween(n:Number, l:Number, u:Number):Number {
            var e:Number = u - l;
            return n < l ? 0 : n > u ? 1 : (n - l) / e;
        }
        
        override public function update():void {
            balanceLayers();
            
            damageBar.value = player.damagePct;
            FP.camera.x = FP.clamp(player.x - 160, 0, _level.width-320-16); // Cut off one tile early
            FP.camera.y = FP.clamp(player.y - 120, 0, _level.height-240);
            
            if(player.dead && --respawnTick <= 0) {
                spawn();
            }
            
            var fell:Boolean = player.y > level.height;
            if(!player.dead && (fell || player.damage >= player.maxDamage)) {
                (fell ? _fallSfx : _crisisSfx).play();
                die(fell ? "You fell into\nthe unknown" : "You succumbed\nto doubt");
            }
            fagsInd.setCharges(player.healCharges, Player.HEAL_MAX_CHARGES);
            
            if(player.x > _level.width - 16) {
                win();
            }
            
            super.update();
        }
    }
}