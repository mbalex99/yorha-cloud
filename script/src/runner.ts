import * as Realm from 'realm';
import * as _ from 'lodash';
import * as faker from 'faker';
import * as superagent from 'superagent';
import * as xml2js from 'xml2js';

const UserSchema: Realm.ObjectSchema = {
  name: 'User',
  primaryKey: 'userId',
  properties: {
    userId: { type: 'string', optional: false, default: faker.random.uuid() },
    spriteUrl: { type: 'string', optional: false, default: '' },
    nickname: { type: 'string', optional: false, default: '' },
    lastSeenTimestamp: { type: 'date', optional: false, default: new Date() },
    latitude: { type: 'double', optional: false, default: 0 },
    longitude: { type: 'double', optional: false, default: 0 },
    thoughts: { type: 'Thought[]' }
  }
}

const ThoughtSchema: Realm.ObjectSchema = {
  name: 'Thought',
  primaryKey: 'thoughtId',
  properties: {
    thoughtId: { type: 'string', optional: false, default: faker.random.uuid() },
    timestamp: { type: 'date', default: new Date(), optional: false },
    body: { type: 'string', default: '', optional: false }
  }
}

async function getSprites() {
  const response = await superagent
    .get('https://s3-us-west-1.amazonaws.com/edensprites/')
    .buffer()
    .type('xml')
    .parse((res, cb) => {
      res.text = '';
      res.on('data', chunk => res.text += chunk);
      res.on('end', () => xml2js.parseString(res.text, cb));
    })
  const spriteUrls = _.flatten(response.body.ListBucketResult.Contents.map(x => x.Key))
    .map(s => `https://s3-us-west-1.amazonaws.com/edensprites/${s}`)
    .filter(s => !_.includes(s, 'blurbs'))
  return spriteUrls
}

async function getRealm(nickname: string = faker.internet.userName()) {
  
  const options = {
    provider: 'nickname',
    providerToken: nickname,
    userInfo: {
      is_admin: true
    }
  };
  const user = await Realm.Sync.User.registerWithProvider(`https://incredible-granite-computer.us1a.cloud.realm.io`, options)
  const realm = await Realm.open({
    sync: {
      url: 'realms://incredible-granite-computer.us1a.cloud.realm.io/main',
      user: user
    }
  })

  const spriteUrls = await getSprites()

  let createdUserObject = undefined;
  realm.write(() => {
    createdUserObject = realm.create('User', {
      userId: user.identity,
      spriteUrl: _.sample(spriteUrls),
      sprite: _.sample(spriteUrls), // dep
      nickname: nickname,
      latitude: faker.random.number({ min: -180, max: 180, precision: 3 }),
      longitude: faker.random.number({ min: -180, max: 180, precision: 3 }),
      lastSeenTimestamp: new Date()
    })
  })
  return {
    realm: realm,
    createdUserObject: createdUserObject
  }
}


async function main() {
  const { realm, createdUserObject } = await getRealm()
  setInterval(() => {
    let newLatitude = createdUserObject.latitude + faker.random.number({ min: -5, max: 5, precision: 0.02 })
    let newLongitude = createdUserObject.longitude + faker.random.number({ min: -5, max: 5, precision: 0.02 })
    if (newLatitude > 180 || newLatitude < -180) {
      newLatitude = faker.random.number({ min: -180, max: 180, precision: 0.02 })
    }
    if (newLongitude > 180 || newLongitude < -180) {
      newLongitude = faker.random.number({ min: -180, max: 180, precision: 0.02 })
    }
    realm.write(() => {
      createdUserObject.latitude = newLatitude
      createdUserObject.longitude = newLongitude
    })
  }, 1000)
}
main()