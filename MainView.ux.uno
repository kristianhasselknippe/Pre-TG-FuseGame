using Fuse;
using Uno;
using Fuse.Controls;
using FuseGame.Audio;

public partial class MainView
{

	readonly MusicPlayer _musicPlayer;

	public MainView()
	{
		
		InitializeUX();
		_musicPlayer = new MusicPlayer(import BundleFile("Audio/music.mp3"));
		//background.FftProvider = new FftProvider(_musicPlayer, 0.0f);
	}
}