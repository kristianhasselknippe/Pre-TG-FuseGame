using Fuse;
using Uno;
using Fuse.Controls;
using FuseGame.Audio;

public partial class MainView
{

	public static MusicPlayer _musicPlayer;

	public MainView()
	{
		_musicPlayer = new MusicPlayer(import BundleFile("Audio/music.mp3"));		
		InitializeUX();
		bloom.FftProvider = new FftProvider(_musicPlayer, 0.0f);
		background.FftProvider = new FftProvider(_musicPlayer, 0.0f);
	}
}