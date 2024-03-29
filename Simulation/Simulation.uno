using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Content;
using Fuse;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Drawing;
using Fuse.Shapes;
using Uno.Geometry;
using FuseGame;

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
		get { return new Rect(Position-(ActualSize*0.5f), ActualSize); }
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
	float RapidFireRate = 15f;

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
		Effects.Add(new PlayerEffect());
		Width = 50;
		Height = 50;
		App.Current.Window.KeyPressed += KeyPressed;
		App.Current.Window.KeyReleased += KeyReleased;

		GameObject.Game.RegisterCollisionCallback(this, OnCollision);
	}

	void OnCollision(GameObject other)
	{
		if (other is Powerup)
		{
			_powerups.Add((Powerup)other);
			GameObject.Destroy(other);
			if (other is Shield)
				Children.Add(((Shield)other).GetAppearance());
		}
		else if (other is Enemy)
			GameObject.Game.Score = 0;
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

		ProcessPowerups(dt);

		_shootTimer += dt;
		if (IsShooting && _shootTimer > 1f/RateOfFire)
		{
			Shoot();
			_shootTimer = 0.0f;
		}
	}

	void ProcessPowerups(float dt)
	{
		var hasRapidFire = false;
		var hasShield = false;
		var hasBoom = false;
		for (int i = 0; i < _powerups.Count; i++)
		{
			_powerups[i].Duration -= dt;
			if (_powerups[i].Duration < 0)
			{
				if (Children.Contains(_powerups[i]))
					Children.Remove(_powerups[i]);
				_powerups.RemoveAt(i);
				continue;
			}
			if (_powerups[i] is RapidFire)
				hasRapidFire = true;
			else if (_powerups[i] is Shield)
				hasShield = true;
			else if (_powerups[i] is Boom)
				hasBoom = true;
		}
		RateOfFire = hasRapidFire ? RapidFireRate : 3;
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
			GameObject.Game.Score += 1;
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
	float EnemySpeed = 1f;

	public Enemy()
	{
		Width = 50;
		Height = 50;
		var pb = new FuseGame.ParticleBatcher(25, 70);
		Appearance = pb;
	}

	public Enemy(float2 pos) : this()
	{
		Position = pos;
	}

	protected override void OnUpdate(float dt)
	{
		var dir = Vector.Normalize(-Position);
		Velocity = dir * EnemySpeed;
	}
}

public class Game : GameObject
{	
	public float SpawnEnemyRate = 1f;
	public float SpawnPowerupRate = 0.1f;

	TextBlock ScoreTextBlock = new TextBlock();

	int _score = 0;
	public int Score
	{
		get { return _score; }
		set
		{
			_score = value;
			ScoreTextBlock.Text = value + "";
		}
	}

	Random rand;
	public Game()
	{
		ScoreTextBlock.FontSize = 50;
		ScoreTextBlock.Alignment = Fuse.Alignment.TopCenter;
		ScoreTextBlock.Text = "0";
		ScoreTextBlock.TextColor = float4(0,0,1,1);
		Children.Add(ScoreTextBlock);

		GameObject.SetGame(this);

		Add(new RapidFire(float2(200,200)));
		Add(new Player());

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

	float _spawnEnemiesTimer = 0f;
	float _spawnPowerupTimer = 0.0f;
	void HandlerSpawning(float dt)
	{
		_spawnEnemiesTimer += dt;
		if (_spawnEnemiesTimer > 1f / SpawnEnemyRate)
		{
			SpawnEnemy();
			_spawnEnemiesTimer = 0f;
		}
		_spawnPowerupTimer += dt;
		if (_spawnPowerupTimer > 1f / SpawnPowerupRate)
		{
			SpawnPowerup();
			_spawnPowerupTimer = 0f;
		}
	}

	Random _rand = new Random(934232);
	void SpawnEnemy()
	{
		var ang = _rand.NextFloat(0, 2f*(float)Math.PI);
		var x = Math.Cos(ang);
		var y = Math.Sin(ang);
		var pos = float2(x,y) * GameObject.ScreenSize;
		GameObject.Instantiate(new Enemy(pos));
	}

	void SpawnPowerup()
	{
		var screenX = GameObject.ScreenSize.X * 0.5f;
		var screenY = GameObject.ScreenSize.Y * 0.5f;
		var x = _rand.NextFloat(-screenX, screenX);
		var y = _rand.NextFloat(-screenY, screenY);
		GameObject.Instantiate(new RapidFire(float2(x,y)));	
	}

	protected override void OnUpdate(float dt)
	{
		HandlerSpawning(dt);
		for (int i = 0; i < _colliders.Count; i++)
		{
			var collider = _colliders[i];
			for (int j = 0; j < _gameObjects.Count; j++)
			{
				var go = _gameObjects[j];
				if (!go.IsCollidable || go == collider.GameObject) continue;

				if (collider.AreColliding(go))
				{
					collider.OnCollision(go);
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


		for (int i = 0; i < _colliders.Count; i++)
		{
			var col = _colliders[i];
			if (col.GameObject == go)
			{
				_colliders.Remove(col);
				return;
			}
		}
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
	public float Duration;

	public virtual Panel GetAppearance()
	{
		return new Panel();
	}

	public Powerup(float2 pos)
	{
		Position = pos;
		Appearance = GetAppearance();
	}
}

public class RapidFire : Powerup
{
	public RapidFire(float2 pos) : base(pos)
	{
		Width = 30;
		Height = 30;
		Duration = 5;
	}

	public override Panel GetAppearance()
	{
		var panel = new Panel();
		panel.Children.Add(new Rectangle()
			{
				Fill = new SolidColor(float4(1,0,0,1))
			});
		return panel;
	}
}

public class Shield : Powerup
{
	public Shield(float2 pos) : base(pos)
	{
	}

	public override Panel GetAppearance()
	{
		Width = 15;
		Height = 15;
		var pb = new ParticleBatcher(20, 100);
		pb.ParticleSize = 8;
		pb.Color = float4(0.7f,0.7f,1,0.2f);
		return pb;
	}
}

public class Boom : Powerup
{
	public Boom(float2 pos) : base(pos){}
}
