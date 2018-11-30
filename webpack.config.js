const path = require('path');
const webpack = require('webpack');

const MiniCssExtractPlugin = require("mini-css-extract-plugin");

module.exports = function(env) {
	const production = process.env.NODE_ENV === 'production';
	return {
		devtool: production ? 'source-maps' : 'eval',
		entry: './assets/app.js',
		output: (production
		? {
			path: path.resolve(__dirname, './priv/static/assets'),
			filename: 'app.js',
			publicPath: '/'
		}
		: {
			path: path.resolve(__dirname, 'public'),
			filename: 'app.js',
			publicPath: 'http://localhost:8080/'
		}),
		module: {
			rules: [
				{
					test: /\.js$/,
					exclude: /node_modules/,
					use: {
						loader: 'babel-loader',
					},
				},
				{
					test: /\.css$/,
					use: [
						{
							loader: MiniCssExtractPlugin.loader
						},
						"css-loader"
					]
				},
					{
						test: /\.(png|jpg|gif)$/,
						exclude: /node_modules/,
						use: [
							{
								loader: 'file-loader',
								options: {
									useRelativePath: production,
									context: path.resolve(__dirname, './assets/static')
								}
							}
						]
					}
			]
		},
		resolve: {
			modules: ['node_modules', path.resolve(__dirname, './assets')],
			extensions: ['.js'],
		},
		devServer: {
			headers: {
				'Access-Control-Allow-Origin': '*',
			},
		},
		plugins: [
			new MiniCssExtractPlugin({filename: "app.css"}),
				new webpack.ProvidePlugin({
						$: "jquery",
						jQuery: "jquery",
						"window.jQuery": "jquery"
				})
		]
	};
};
