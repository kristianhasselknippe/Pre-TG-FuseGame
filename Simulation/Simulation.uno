using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Content;
using Fuse;
using Fuse.Controls;
using Fuse.Drawing;
using Fuse.Shapes;
using Uno.Geometry;

public class GameObject : Panel
{
	public static Game Game { get; set; }

	public static void SetGame(Game g)
	{
		Game = g;
	}

	public static float2 ScreenSize
	{
		get { return Game.ActualSize; }
	}

	public static void Instantiate(GameObject go)
	{
		Game.Add(go);
		debug_log "Instantiated: " + go + ", TotalObjects: " + Game.Children.Count;
	}

	public static void 	Destroy(GameObject go)
	{
		if (Game.Children.Contains(go))
		{
			Game.Remove(go);
			debug_log "Destroyed: " + go + ", TotalObjects: " + Game.Children.Count;
		}
	}

	public float Acceleration = 5f;
	public float RotationSpeed = 5f;

	protected bool DisableUpdate { get; set; }

	Translation _trans = new Translation();
	public float2 Position
	{
		get { return _trans.Vector.XY; }
		set { _trans.Vector = float3(value, 0); }
	}

	Rotation _rot = new Rotation();
	public float Rotation
	{
		get { return _rot.Degrees; }
		set { _rot.Degrees = value; }
	}

	float2 _velocity = float2();
	protected float2 Velocity
	{
		get { return _velocity; }
		set { _velocity = value; }
	}

	public Rect BoundingBox
	{
		get { return new Rect(Position, ActualSize); }
	}

	bool _isCollidable = true;
	public bool IsCollidable
	{
		get { return _isCollidable; }
		set { _isCollidable = value; }
	}

	protected GameObject()
	{
		Transforms.Add(_trans);
		Transforms.Add(_rot);
		Update += OnBaseUpdate;
	}

	void OnBaseUpdate(object sender, EventArgs args)
	{
		if (DisableUpdate) return;
		var dt = Fuse.Time.FrameInterval;
		OnUpdate(dt);
		Position += Velocity;
	}

	protected virtual void OnUpdate(float dt) {}

}


public class Player : GameObject
{
	float RateOfFire = 3f;

	List<Powerup> _powerups = new List<Powerup>();

	bool _wDown = false;
	float Up { get { return _wDown ? 1 : 0; } }
	bool _aDown = false;
	float Left { get { return _aDown ? -1 : 0; } }
	bool _sDown = false;
	float Down { get { return _sDown ? -1 : 0; } }
	bool _dDown = false;
	float Right { get { return _dDown ? 1 : 0; } }
	bool _spaceDown = false;
	bool IsShooting { get { return _spaceDown; } }

	public Player()
	{
		var image = new Image();
		image.Texture = import Texture2D("../Assets/player.png");
		image.Transforms.Add(new Rotation()
		{
			Degrees = 90
		});
		Appearance = image;
		Width = 50;
		Height = 50;
		App.Current.Window.KeyPressed += KeyPressed;
		App.Current.Window.KeyReleased += KeyReleased;

		GameObject.Game.RegisterCollisionCallback(this, OnCollision);
	}

	void OnCollision(GameObject other)
	{
		if (other is Powerup)
			_powerups.Add((Powerup)other);
	}

	public Player(float2 position) : this()
	{
		Position = position;
	}

	float _shootTimer = 0f;
	protected override void OnUpdate(float dt)
	{
		ProcessInput(dt);

		var screenSize = GameObject.ScreenSize;
		if (Position.X > screenSize.X * 0.5f || Position.X < screenSize.X * -0.5f)
			Position = float2(-Position.X, Position.Y);
		if (Position.Y > screenSize.Y * 0.5f || Position.Y < screenSize.Y * -0.5f)
			Position = float2(Position.X, -Position.Y);

		ProcessPowerups();

		_shootTimer += dt;
		if (IsShooting && _shootTimer > 1f/RateOfFire)
		{
			Shoot();
			_shootTimer = 0.0f;
		}
	}

	void ProcessPowerups()
	{
		var hasRapidFire = false;
		var hasShield = false;
		var hasBoom = false;
		for (int i = 0; i < _powerups.Count; i++)
		{
			if (_powerups[i] is RapidFire)
				hasRapidFire = true;
			else if (_powerups[i] is Shield)
				hasShield = true;
			else if (_powerups[i] is Boom)
				hasBoom = true;
		}
		RateOfFire = hasRapidFire ? 10 : 3;
	}

	void ProcessInput(float dt)
	{
		var rotation = Math.DegreesToRadians(Rotation);
		var input = Up + Down;
		var velDelta = input * dt;

		var rot = Left + Right;
		var rotDelta = rot * dt * RotationSpeed;

		Rotation += Math.RadiansToDegrees(rotDelta);
		var x = Math.Cos(rotation);
		var y = Math.Sin(rotation);
		var dir = Vector.Normalize(float2(x,y)) * Acceleration;

		Velocity += velDelta * dir;
	}

	void KeyPressed(object sender, Uno.Platform.KeyEventArgs args)
	{
		switch (args.Key)
		{
			case Uno.Platform.Key.W:
				_wDown = true;
				break;
			case Uno.Platform.Key.A:
				_aDown = true;
				break;
			case Uno.Platform.Key.S:
				_sDown = true;
				break;
			case Uno.Platform.Key.D:
				_dDown = true;
				break;
			case Uno.Platform.Key.Space:
				_spaceDown = true;
				break;
		}
	}

	void Shoot()
	{
		GameObject.Instantiate(new Bullet(Position, Rotation));
	}

	void KeyReleased(object sender, Uno.Platform.KeyEventArgs args)
	{
		switch (args.Key)
		{
			case Uno.Platform.Key.W:
				_wDown = false;
				break;
			case Uno.Platform.Key.A:
				_aDown = false;
				break;
			case Uno.Platform.Key.S:
				_sDown = false;
				break;
			case Uno.Platform.Key.D:
				_dDown = false;
				break;
			case Uno.Platform.Key.Space:
				_spaceDown = false;
				break;
		}
	}
}

public class Bullet : GameObject
{
	public float BulletSpeed = 10f;

	public Bullet(float2 position, float rotation)
	{
		Width = 15;
		Height = 5;
		Appearance = new Rectangle()
		{
			Fill = new SolidColor(float4(1,0,0,1))
		};
		Position = position;
		Rotation = rotation;
		var rot = Math.DegreesToRadians(Rotation);
		var x = Math.Cos(rot);
		var y = Math.Sin(rot);
		var dir = Vector.Normalize(float2(x,y));
		Velocity = dir * BulletSpeed;

		GameObject.Game.RegisterCollisionCallback(this, OnCollision);
	}

	void OnCollision(GameObject other)
	{
		if (other is Enemy)
		{
			GameObject.Destroy(other);
			GameObject.Destroy(this);
		}
		
	}

	protected override void OnUpdate(float dt)
	{
		if (Vector.Distance(Position, float2(0,0)) > 2000)
		{
			GameObject.Destroy(this);
		}
	}

}

public class Enemy : GameObject
{
	public Enemy()
	{
		Width = 50;
		Height = 50;
		Appearance = new Rectangle()
		{
			Fill = new SolidColor(float4(1,0,0,1))
		};	
	}

	public Enemy(float2 pos) : this()
	{
		Position = pos;
	}

}

public class Game : GameObject
{
	public Game()
	{
		GameObject.SetGame(this);

		Add(new Player());
		Add(new Enemy(float2(100,100)));
		Add(new Enemy(float2(-100,100)));
		Add(new Enemy(float2(100,-100)));
		Add(new Enemy(float2(-100,-100)));

		Add(new RapidFire(float2(200,200)));
	}

	List<GameObject> _gameObjects = new List<GameObject>();
	public List<GameObject> GameObjects
	{
		get { return _gameObjects; }
	}

 	List<Collider> _colliders = new List<Collider>();

	public void RegisterCollisionCallback(GameObject go, Action<GameObject> onCollision)
	{
		_colliders.Add(new Collider(go, onCollision));
	}

	protected override void OnUpdate(float dt)
	{
		for (int i = 0; i < _colliders.Count; i++)
		{
			var collider = _colliders[i];
			for (int j = 0; j < _gameObjects.Count; j++)
			{
				var go = _gameObjects[j];
				if (!go.IsCollidable || go == collider.GameObject) continue;

				if (collider.AreColliding(go))
				{
					_colliders[i].OnCollision(go);
				}
			}
		}
	}

	public void Add(GameObject go)
	{
		_gameObjects.Add(go);
		Children.Add(go);
	}

	public void Remove(GameObject go)
	{
		if (_gameObjects.Contains(go))
			_gameObjects.Remove(go);
		if (Children.Contains(go))
			Children.Remove(go);
	}
}

public class Collider
{
	public readonly GameObject GameObject;
	public readonly Action<GameObject> OnCollision;
	public Collider(GameObject go, Action<GameObject> onCollision)
	{
		GameObject = go;
		OnCollision = onCollision;
	}

	public bool AreColliding(GameObject other)
	{
		return 
			!(other.BoundingBox.Left > GameObject.BoundingBox.Right || 
        	other.BoundingBox.Right < GameObject.BoundingBox.Left || 
        	other.BoundingBox.Top > GameObject.BoundingBox.Bottom ||
        	other.BoundingBox.Bottom < GameObject.BoundingBox.Top);
	}
}

public class Powerup : GameObject
{
	public Powerup(float2 pos)
	{
		Position = pos;
	}
}

public class RapidFire : Powerup
{
	public RapidFire(float2 pos) : base(pos)
	{
		Width = 30;
		Height = 30;
		Appearance = new Rectangle()
		{
			Fill = new SolidColor(float4(0,1,1,1))
		};
	}
}

public class Shield : Powerup
{
	public Shield(float2 pos) : base(pos){}
}

public class Boom : Powerup
{
	public Boom(float2 pos) : base(pos){}
}
