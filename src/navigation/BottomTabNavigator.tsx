import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import Calendar from '../screens/Calendar';
import type { BottomTabParamList } from '../types/navigation';

const Tab = createBottomTabNavigator<BottomTabParamList>();

// 모든 화면에서 공통으로 쓰이는 하단 탭 바
export default function BottomTabNavigator() {
  return (
    <Tab.Navigator initialRouteName="Calendar">
      <Tab.Screen name="Calendar" component={Calendar} />
    </Tab.Navigator>
  );
}
