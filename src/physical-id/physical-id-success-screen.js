// @flow

import React from 'react'
import { View, Text, StyleSheet } from 'react-native'
import Icon from 'react-native-vector-icons/FontAwesome'
import { useNavigation } from '@react-navigation/native'
import LottieView from 'lottie-react-native'

import { physicalIdSuccessRoute } from '../common/route-constants'
import { modalOptions } from '../connection-details/utils/modalOptions'
import { colors, fontFamily, fontSizes } from '../common/styles'
import { Button } from '../components/buttons/button'
import { verticalScale } from 'react-native-size-matters'

function PhysicalIdSuccess() {
  const navigation = useNavigation()
  const onDone = () => {
    navigation.goBack()
  }

  return (
    <View style={style.container}>
      <View style={style.infoContainer}>
        <Text style={style.titleText}>
          Success! Your information is being verified.
        </Text>
        <View style={style.iconContainer}>
          <LottieView
            source={require('../images/green-tick-lottie.json')}
            autoPlay
            loop={false}
            style={style.feedbackIcon}
          />
        </View>
        <Text style={style.descriptionText}>
          Your document and facial scan are being reviewed. If everything cheks
          out, you will receive a credential offer. This can take up to an hour.
        </Text>
      </View>
      <View style={style.actionContainer}>
        <Button onPress={onDone} label="OK" />
      </View>
    </View>
  )
}

const style = StyleSheet.create({
  container: {
    flex: 1,
  },
  infoContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: '8%',
  },
  titleText: {
    fontSize: verticalScale(fontSizes.size5),
    fontWeight: '400',
    color: colors.gray1,
    fontFamily: fontFamily,
    textAlign: 'center',
  },
  descriptionText: {
    lineHeight: 25,
    fontSize: verticalScale(fontSizes.size6),
    fontWeight: '400',
    color: colors.gray1,
    fontFamily: fontFamily,
    // textAlign: 'left',
  },
  iconContainer: {
    marginVertical: '5%',
  },
  feedbackIcon: {
    width: 150,
    height: 150,
  },
  actionContainer: {
    width: '100%',
  },
})

const headline = ''
export const physicalIdSuccessScreen = {
  routeName: physicalIdSuccessRoute,
  screen: PhysicalIdSuccess,
  headline,
  navigationOptions: modalOptions(headline, 'CloseIcon'),
}
