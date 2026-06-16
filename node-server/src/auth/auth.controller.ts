import { Body, Controller, Get, Inject, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { UserId } from '../common/user-id.decorator';
import { STORE, Store } from '../db/store.interface';
import { User } from '../models/types';
import { AuthService } from './auth.service';
import { PhoneLoginDto, PhonePasswordDto, SendCodeDto, WechatLoginDto } from './dto';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    @Inject(STORE) private readonly store: Store,
  ) {}

  // 微信登录：小程序 wx.login 拿到 code 后调用
  @Post('wechat')
  wechat(@Body() dto: WechatLoginDto) {
    return this.auth.loginWithWechat(dto.code);
  }

  // 手机号登录：发验证码
  @Post('phone/code')
  sendCode(@Body() dto: SendCodeDto) {
    return this.auth.sendPhoneCode(dto.phone);
  }

  // 手机号登录：校验登录（短信验证码，预留）
  @Post('phone/login')
  phoneLogin(@Body() dto: PhoneLoginDto) {
    return this.auth.loginWithPhone(dto.phone, dto.code);
  }

  // 手机号+密码：注册
  @Post('phone/register')
  phoneRegister(@Body() dto: PhonePasswordDto) {
    return this.auth.registerWithPhonePassword(dto.phone, dto.password);
  }

  // 手机号+密码：登录
  @Post('phone/password-login')
  phonePasswordLogin(@Body() dto: PhonePasswordDto) {
    return this.auth.loginWithPhonePassword(dto.phone, dto.password);
  }

  // 当前登录用户
  @Get('me')
  @UseGuards(JwtAuthGuard)
  async me(@UserId() userId: string) {
    const u = await this.store.users.findById(userId);
    return { user: this.auth.publicUser(u as User) };
  }
}
