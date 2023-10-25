import 'package:pocketbase/pocketbase.dart';

import 'base.dart';

/// Launch url with [url_launcher] or [flutter_custom_tabs]
typedef AuthUrlLauncher = void Function(Uri url);

abstract class OAuth2AuthProvider extends AuthProvider {
  @override
  final String name;

  final List<String> scopes;

  OAuth2AuthProvider({
    required this.name,
    required this.label,
    this.scopes = const <String>[],
  });

  @override
  bool isSupported(AuthMethodsList value) {
    return value.authProviders.any((e) => e.name == name);
  }

  Future<void> authenticate(
    AuthUrlLauncher urlLauncher, {
    final Map<String, dynamic> createData = const {},
  }) async {
    await authService.authWithOAuth2(
      name,
      urlLauncher,
      scopes: scopes,
      createData: createData,
    );
  }

  Future<void> unlink() async {
    if (userId == null) return;
    await authService.unlinkExternalAuth(userId!, name);
  }

  bool isLinked(List<ExternalAuthModel> values) {
    if (userId == null) return false;
    return values.any((e) => e.provider == name);
  }

  final String label;
}

class AppleAuthProvider extends OAuth2AuthProvider {
  AppleAuthProvider({super.scopes = const []})
      : super(name: 'apple', label: 'Apple');
}

class GoogleAuthProvider extends OAuth2AuthProvider {
  GoogleAuthProvider({super.scopes = const []})
      : super(name: 'google', label: 'Google');
}

class MicrosoftAuthProvider extends OAuth2AuthProvider {
  MicrosoftAuthProvider({super.scopes = const []})
      : super(name: 'microsoft', label: 'Microsoft');
}

class YandexAuthProvider extends OAuth2AuthProvider {
  YandexAuthProvider({super.scopes = const []})
      : super(name: 'yandex', label: 'Yandex');
}

class FacebookAuthProvider extends OAuth2AuthProvider {
  FacebookAuthProvider({super.scopes = const []})
      : super(name: 'facebook', label: 'Facebook');
}

class InstagramAuthProvider extends OAuth2AuthProvider {
  InstagramAuthProvider({super.scopes = const []})
      : super(name: 'instagram', label: 'Instagram');
}

class GitHubAuthProvider extends OAuth2AuthProvider {
  GitHubAuthProvider({super.scopes = const []})
      : super(name: 'github', label: 'GitHub');
}

class GitLabAuthProvider extends OAuth2AuthProvider {
  GitLabAuthProvider({super.scopes = const []})
      : super(name: 'gitlab', label: 'GitLab');
}

class GiteeAuthProvider extends OAuth2AuthProvider {
  GiteeAuthProvider({super.scopes = const []})
      : super(name: 'gitee', label: 'Gitee');
}

class GiteaAuthProvider extends OAuth2AuthProvider {
  GiteaAuthProvider({super.scopes = const []})
      : super(name: 'gitea', label: 'Gitea');
}

class DiscordAuthProvider extends OAuth2AuthProvider {
  DiscordAuthProvider({super.scopes = const []})
      : super(name: 'discord', label: 'Discord');
}

class TwitterAuthProvider extends OAuth2AuthProvider {
  TwitterAuthProvider({super.scopes = const []})
      : super(name: 'twitter', label: 'Twitter');
}

class KakaoAuthProvider extends OAuth2AuthProvider {
  KakaoAuthProvider({super.scopes = const []})
      : super(name: 'kakao', label: 'Kakao');
}

class VKAuthProvider extends OAuth2AuthProvider {
  VKAuthProvider({super.scopes = const []}) : super(name: 'vk', label: 'VK');
}

class SpotifyAuthProvider extends OAuth2AuthProvider {
  SpotifyAuthProvider({super.scopes = const []})
      : super(name: 'spotify', label: 'Spotify');
}

class TwitchAuthProvider extends OAuth2AuthProvider {
  TwitchAuthProvider({super.scopes = const []})
      : super(name: 'twitch', label: 'Twitch');
}

class PatreonAuthProvider extends OAuth2AuthProvider {
  PatreonAuthProvider({super.scopes = const []})
      : super(name: 'patreon', label: 'Patreon');
}

class StravaAuthProvider extends OAuth2AuthProvider {
  StravaAuthProvider({super.scopes = const []})
      : super(name: 'strava', label: 'Strava');
}

class LiveChatAuthProvider extends OAuth2AuthProvider {
  LiveChatAuthProvider({super.scopes = const []})
      : super(name: 'livechat', label: 'LiveChat');
}

class MailcowAuthProvider extends OAuth2AuthProvider {
  MailcowAuthProvider({super.scopes = const []})
      : super(name: 'mailcow', label: 'mailcow');
}

class OpenIDConnectAuthProvider extends OAuth2AuthProvider {
  OpenIDConnectAuthProvider({super.scopes = const []})
      : super(name: 'oidc', label: 'OpenID Connect');
}

class OpenIDConnect2AuthProvider extends OAuth2AuthProvider {
  OpenIDConnect2AuthProvider({super.scopes = const []})
      : super(name: 'oidc2', label: 'OpenID Connect 2');
}

class OpenIDConnect3AuthProvider extends OAuth2AuthProvider {
  OpenIDConnect3AuthProvider({super.scopes = const []})
      : super(name: 'oidc3', label: 'OpenID Connect 3');
}
