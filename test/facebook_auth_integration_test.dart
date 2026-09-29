import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/services/facebook_auth_service.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';

void main() {
  group('Facebook Auth Data Models & Service Tests', () {
    test('FacebookUserData.fromMap parses complete Graph API payload', () {
      final payload = {
        'id': '10229384758291029',
        'name': 'Carlos Mendoza',
        'email': 'carlos.mendoza@example.com',
        'picture': {
          'data': {
            'height': 200,
            'is_silhouette': false,
            'url': 'https://platform-lookaside.fbsbx.com/platform/profilepic/?asid=10229384758291029',
            'width': 200,
          },
        },
      };

      final user = FacebookUserData.fromMap(payload);
      expect(user.id, equals('10229384758291029'));
      expect(user.name, equals('Carlos Mendoza'));
      expect(user.email, equals('carlos.mendoza@example.com'));
      expect(
        user.avatarUrl,
        equals('https://platform-lookaside.fbsbx.com/platform/profilepic/?asid=10229384758291029'),
      );
    });

    test('FacebookUserData.fromMap handles missing picture and email gracefully', () {
      final payload = {
        'id': '99887766',
        'name': 'Ana Perez',
      };

      final user = FacebookUserData.fromMap(payload);
      expect(user.id, equals('99887766'));
      expect(user.name, equals('Ana Perez'));
      expect(user.email, isNull);
      expect(user.avatarUrl, isNull);
    });

    test('FacebookAuthResponse factory constructors return correct states', () {
      const user = FacebookUserData(
        id: '123',
        name: 'Tester',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      final success = FacebookAuthResponse.success(user);
      expect(success.isSuccess, isTrue);
      expect(success.isCancelled, isFalse);
      expect(success.userData?.name, equals('Tester'));

      final cancelled = FacebookAuthResponse.cancelled();
      expect(cancelled.isSuccess, isFalse);
      expect(cancelled.isCancelled, isTrue);

      final failed = FacebookAuthResponse.failed('Error de red');
      expect(failed.isSuccess, isFalse);
      expect(failed.isCancelled, isFalse);
      expect(failed.errorMessage, equals('Error de red'));
    });
  });

  group('PlayerSession Facebook Binding & Persistence Tests', () {
    test('Default session starts with Facebook unlinked', () {
      final session = PlayerSession.createDefault();
      expect(session.isFacebookLinked, isFalse);
      expect(session.facebookId, isNull);
      expect(session.facebookName, isNull);
      expect(session.facebookAvatarUrl, isNull);
      expect(session.useFacebookAvatar, isFalse);
      expect(session.activeAvatarUrl, isNull);
    });

    test('linkFacebook binds identity and updates player name & avatar', () {
      final session = PlayerSession.createDefault();

      session.linkFacebook(
        id: 'fb_445566',
        name: 'Yohan Cast',
        avatarUrl: 'https://graph.facebook.com/photo.jpg',
        email: 'yohan@test.com',
      );

      expect(session.isFacebookLinked, isTrue);
      expect(session.facebookId, equals('fb_445566'));
      expect(session.facebookName, equals('Yohan Cast'));
      expect(session.name, equals('Yohan Cast'));
      expect(session.facebookAvatarUrl, equals('https://graph.facebook.com/photo.jpg'));
      expect(session.facebookEmail, equals('yohan@test.com'));
      expect(session.useFacebookAvatar, isTrue);
      expect(session.activeAvatarUrl, equals('https://graph.facebook.com/photo.jpg'));
    });

    test('setUseFacebookAvatar toggles avatar selection between FB and local hero', () {
      final session = PlayerSession.createDefault();
      session.linkFacebook(
        id: 'fb_1',
        name: 'Maria',
        avatarUrl: 'https://graph.facebook.com/m.jpg',
      );

      expect(session.useFacebookAvatar, isTrue);
      expect(session.activeAvatarUrl, equals('https://graph.facebook.com/m.jpg'));

      session.setUseFacebookAvatar(false);
      expect(session.useFacebookAvatar, isFalse);
      expect(session.activeAvatarUrl, isNull);

      session.setUseFacebookAvatar(true);
      expect(session.useFacebookAvatar, isTrue);
      expect(session.activeAvatarUrl, equals('https://graph.facebook.com/m.jpg'));
    });

    test('unlinkFacebook clears all Facebook data but retains earned rewards', () {
      final session = PlayerSession.createDefault();
      session.linkFacebook(
        id: 'fb_1',
        name: 'Maria',
        avatarUrl: 'https://graph.facebook.com/m.jpg',
        email: 'maria@test.com',
      );

      session.unlinkFacebook();

      expect(session.isFacebookLinked, isFalse);
      expect(session.facebookId, isNull);
      expect(session.facebookName, isNull);
      expect(session.facebookAvatarUrl, isNull);
      expect(session.facebookEmail, isNull);
      expect(session.useFacebookAvatar, isFalse);
      expect(session.activeAvatarUrl, isNull);
      expect(session.hasClaimedFacebookReward, isTrue);
      expect(session.coins, equals(PlayerSession.facebookRewardCoins));
      expect(session.chapas, equals(PlayerSession.facebookRewardChapas));
    });

    test('linkFacebook grants welcome reward exactly once preventing re-claim exploits', () {
      final session = PlayerSession.createDefault(coins: 0);
      expect(session.coins, equals(0));
      expect(session.chapas, equals(0));
      expect(session.xp, equals(0));
      expect(session.hasClaimedFacebookReward, isFalse);

      // Primer link: otorga recompensa
      final firstRewardResult = session.linkFacebook(
        id: 'fb_100',
        name: 'Carlos',
        avatarUrl: 'https://graph.facebook.com/c.jpg',
      );
      expect(firstRewardResult, isTrue);
      expect(session.coins, equals(PlayerSession.facebookRewardCoins));
      expect(session.chapas, equals(PlayerSession.facebookRewardChapas));
      expect(session.xp, equals(PlayerSession.facebookRewardXp));
      expect(session.hasClaimedFacebookReward, isTrue);

      // Desvincula
      session.unlinkFacebook();
      expect(session.isFacebookLinked, isFalse);
      expect(session.coins, equals(PlayerSession.facebookRewardCoins));

      // Segundo link: NO otorga duplicados
      final secondRewardResult = session.linkFacebook(
        id: 'fb_100',
        name: 'Carlos',
        avatarUrl: 'https://graph.facebook.com/c.jpg',
      );
      expect(secondRewardResult, isFalse);
      expect(session.coins, equals(PlayerSession.facebookRewardCoins));
      expect(session.chapas, equals(PlayerSession.facebookRewardChapas));
    });

    test('toJson and fromJson preserve Facebook session state and claimed reward flag', () {
      final session = PlayerSession.createDefault();
      session.linkFacebook(
        id: 'fb_8899',
        name: 'Pedro Perez',
        avatarUrl: 'https://graph.facebook.com/pedro.jpg',
        email: 'pedro@caidago.com',
      );

      final json = session.toJson();
      final restored = PlayerSession.fromJson(json);

      expect(restored.isFacebookLinked, isTrue);
      expect(restored.facebookId, equals('fb_8899'));
      expect(restored.facebookName, equals('Pedro Perez'));
      expect(restored.name, equals('Pedro Perez'));
      expect(restored.facebookAvatarUrl, equals('https://graph.facebook.com/pedro.jpg'));
      expect(restored.facebookEmail, equals('pedro@caidago.com'));
      expect(restored.useFacebookAvatar, isTrue);
      expect(restored.activeAvatarUrl, equals('https://graph.facebook.com/pedro.jpg'));
      expect(restored.hasClaimedFacebookReward, isTrue);
      expect(restored.coins, equals(PlayerSession.facebookRewardCoins));
      expect(restored.chapas, equals(PlayerSession.facebookRewardChapas));
    });
  });
}
