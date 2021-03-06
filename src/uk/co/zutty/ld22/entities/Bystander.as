package uk.co.zutty.ld22.entities
{
    import net.flashpunk.Entity;
    import net.flashpunk.FP;
    import net.flashpunk.Sfx;
    import net.flashpunk.graphics.Image;
    import net.flashpunk.graphics.Spritemap;
    
    import uk.co.zutty.ld22.Main;
    import uk.co.zutty.ld22.worlds.GameWorld;

    public class Bystander extends Speaker {
        
        public static const QUOTES_L0:Array = [
            "Lovely weather",
            "Isn't life grand",
            "I like cake",
            "Did you see that TV show?",
            "Cheer up!",
            "My brain hurts"
        ];

        [Embed(source = 'assets/bystander.png')]
        private const BYSTANDER_IMAGE:Class;
        
        [Embed(source = 'assets/poof.mp3')]
        private const POOF_SOUND:Class;

        private var _img:Spritemap;
        private var _target:Entity;
        private var _jumped:Boolean;
        private var _poofSfx:Sfx;

        public function Bystander(x:Number, y:Number) {
            super(x, y);
            _poofSfx = new Sfx(POOF_SOUND);
            _img = new Spritemap(BYSTANDER_IMAGE, 16, 32);
            _img.add("right", [0], 20, true);
            _img.add("left", [1], 20, true);
            _img.centerOrigin();
            _img.play("left");
            graphic = _img;
            setHitbox(16, 32, 8, 16);
            speakCooldown = 200;
            _damage = 0;
            _maxDamage = 3;
            active = true;
            visible = true;
        }

        public function set target(t:Entity):void {
            _target = t;
        }
        
        public function get targetInRange():Boolean {
            return true;
        }
        
        override public function doFire(char:String):void {
            Banality(GameWorld(FP.world).banalities.next()).fireAt(char, x, y, velocity, _target);            
        }
        
        public function die():void {
            active = false;
            visible = false;
            _poofSfx.play();
            if(FP.world is GameWorld) {
                for(var i:int = 0; i < 4; i++) {
                    Cloud(GameWorld(FP.world).clouds.next()).poof(x, y);
                }
            }
        }
        
        override public function update():void {
            super.update();
            
            if(_target) {
                _img.play(_target.x < x ? "left" : "right");
            }
            
            var bullet:Entity = collide("bullet", x, y);
            if(bullet && bullet.active) {
                _damage += 1;
                bullet.collidable = false;
            }
            
            if(_damage >= maxDamage) {
                _damage = maxDamage;
                die();
            }
            
            if(_target && targetInRange && canSpeak) {
                speak(FP.choose(QUOTES_L0), _target.x > x);
            }
        }
    }
}